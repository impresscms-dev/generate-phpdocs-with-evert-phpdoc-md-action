import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { randomUUID } from "node:crypto";
import { cp, mkdtemp, readFile, readdir, rm, stat } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { GenericContainer } from "testcontainers";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const fixtureProjectPath = path.join(__dirname, "fixtures", "example-project");
const dockerExecutable = process.env.DOCKER_BIN || "docker";
const hostUid = typeof process.getuid === "function" ? process.getuid() : null;
const hostGid = typeof process.getgid === "function" ? process.getgid() : null;

async function runDockerCommand(args) {
  return await new Promise((resolve, reject) => {
    let output = "";
    const childProcess = spawn(dockerExecutable, args, {
      cwd: repoRoot,
      stdio: ["ignore", "pipe", "pipe"]
    });

    childProcess.stdout.on("data", (chunk) => {
      output += chunk.toString();
    });
    childProcess.stderr.on("data", (chunk) => {
      output += chunk.toString();
    });
    childProcess.on("error", reject);
    childProcess.on("exit", (code) => {
      if (code === 0) {
        resolve(output.trim());
      } else {
        reject(new Error(output.trim() || `docker ${args.join(" ")} failed with exit code ${code ?? "unknown"}`));
      }
    });
  });
}

async function buildActionImage(phpVersion) {
  const imageTag = `local/phpdocs-action-test:${randomUUID()}`;
  const args = ["build", "--build-arg", `PHP_VERSION=${phpVersion}`, "-t", imageTag, "."];

  await new Promise((resolve, reject) => {
    const childProcess = spawn(dockerExecutable, args, {
      cwd: repoRoot,
      stdio: "inherit"
    });

    childProcess.on("error", (error) => {
      reject(new Error(`Failed to execute '${dockerExecutable}'. Set DOCKER_BIN if Docker is not on PATH. ${error.message}`));
    });
    childProcess.on("exit", (code) => {
      if (code === 0) {
        resolve();
      } else {
        reject(new Error(`docker build failed for PHP_VERSION=${phpVersion}`));
      }
    });
  });

  return imageTag;
}

async function runAction(actionImage, ignoredFiles, phpDocumentorVersion) {
  const workspacePath = await mkdtemp(path.join(os.tmpdir(), "phpdoc-action-workspace-"));

  await cp(fixtureProjectPath, workspacePath, { recursive: true });

  const docsOutputPath = path.join(workspacePath, "docs");
  const runId = randomUUID();

  const container = new GenericContainer(actionImage)
    .withEntrypoint(["/bin/sh", "-lc"])
    .withCommand(["while true; do sleep 3600; done"])
    .withBindMounts([
      {
        source: workspacePath,
        target: "/github/workspace",
        mode: "rw"
      }
    ])
    .withEnvironment({
      GITHUB_WORKSPACE: "/github/workspace",
      GITHUB_RUN_ID: runId,
      GITHUB_SHA: runId
    })
    .withWorkingDir("/github/workspace");

  if (hostUid !== null && hostGid !== null) {
    container.withUser(`${hostUid}:${hostGid}`);
  }

  let startedContainer;
  try {
    startedContainer = await container.start();
    const execResult = await startedContainer.exec([
      "/usr/local/bin/entrypoint.sh",
      "docs",
      ignoredFiles,
      phpDocumentorVersion
    ]);

    if (execResult.exitCode !== 0) {
      const stderr = execResult.output
        .filter((line) => line.type === "STDERR")
        .map((line) => line.content)
        .join("\n");
      const stdout = execResult.output
        .filter((line) => line.type === "STDOUT")
        .map((line) => line.content)
        .join("\n");

      throw new Error(
        `Action execution failed with exit code ${execResult.exitCode}\nSTDOUT:\n${stdout}\nSTDERR:\n${stderr}`
      );
    }
  } catch (error) {
    if (startedContainer) {
      const containerId = startedContainer.getId();
      try {
        const containerLogs = await runDockerCommand(["logs", containerId]);
        error = new Error(`${error.message}\nContainer logs:\n${containerLogs}`);
      } catch {
        // Fall back to the original error if container logs cannot be read.
      }
    }
    throw error;
  } finally {
    if (startedContainer) {
      await startedContainer.stop().catch(() => {});
    }
  }

  return {
    docsOutputPath,
    workspacePath
  };
}

const phpVersion = process.env.PHP_VERSION || "7.4";
const phpDocumentorVersion = process.env.PHPDOC_VERSION || "v2.8.5";

test(`boots container and generates markdown (php:${phpVersion}-cli)`, async () => {
  const actionImage = await buildActionImage(phpVersion);
  const { docsOutputPath, workspacePath } = await runAction(actionImage, "", phpDocumentorVersion);

  try {
    const indexStat = await stat(path.join(docsOutputPath, "ApiIndex.md"));
    assert.equal(indexStat.isFile(), true);

    const docsFiles = await readdir(docsOutputPath);
    const classDocFiles = docsFiles.filter((fileName) => fileName.endsWith(".md") && fileName !== "ApiIndex.md");
    assert.equal(classDocFiles.length > 0, true);

    const indexContents = await readFile(path.join(docsOutputPath, "ApiIndex.md"), "utf8");
    assert.match(indexContents, /ExampleClass/);
    assert.match(indexContents, /IgnoredClass/);
  } finally {
    await rm(workspacePath, { force: true, recursive: true });
  }
});
