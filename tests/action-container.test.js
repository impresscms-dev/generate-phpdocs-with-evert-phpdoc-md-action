import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { randomUUID } from "node:crypto";
import { cp, mkdtemp, readFile, readdir, rm, stat } from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { GenericContainer, Wait } from "testcontainers";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const fixtureProjectPath = path.join(__dirname, "fixtures", "example-project");
const dockerExecutable = process.env.DOCKER_BIN || "docker";
const hostUid = typeof process.getuid === "function" ? process.getuid() : null;
const hostGid = typeof process.getgid === "function" ? process.getgid() : null;

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
    .withWorkingDir("/github/workspace")
    .withWaitStrategy(Wait.forOneShotStartup())
    .withCommand(["docs", ignoredFiles, phpDocumentorVersion]);

  if (hostUid !== null && hostGid !== null) {
    container.withUser(`${hostUid}:${hostGid}`);
  }

  await container.start();

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
