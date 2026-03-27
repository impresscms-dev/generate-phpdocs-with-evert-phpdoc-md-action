import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { cp, mkdtemp, readFile, readdir, rm, stat } from "node:fs/promises";
import { existsSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";

import { GenericContainer, Wait } from "testcontainers";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const repoRoot = path.resolve(__dirname, "..");
const fixtureProjectPath = path.join(__dirname, "fixtures", "example-project");
const dockerDesktopPath = "C:\\Program Files\\Docker\\Docker\\resources\\bin";

if (process.platform === "win32" && existsSync(path.join(dockerDesktopPath, "docker.exe"))) {
  process.env.PATH = `${dockerDesktopPath};${process.env.PATH}`;
}

async function buildActionImage(phpImage) {
  return GenericContainer.fromDockerfile(repoRoot)
    .withBuildArgs({
      PHP_IMAGE: phpImage
    })
    .build();
}

async function runAction(actionContainer, ignoredFiles, phpDocumentorVersion) {
  const workspacePath = await mkdtemp(path.join(os.tmpdir(), "phpdoc-action-workspace-"));

  await cp(fixtureProjectPath, workspacePath, { recursive: true });

  const docsOutputPath = path.join(workspacePath, "docs");
  const runId = randomUUID();

  const container = await actionContainer
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
    .withCommand(["docs", ignoredFiles, phpDocumentorVersion])
    .start();

  return {
    docsOutputPath,
    workspacePath
  };
}

const testMatrix = [
  {
    phpImage: "php:5.5.38-cli",
    phpDocumentorVersion: "v2.8.5"
  },
  {
    phpImage: "php:7.4-cli",
    phpDocumentorVersion: "v2.8.5"
  }
];

for (const scenario of testMatrix) {
  test(`boots container and generates markdown (${scenario.phpImage})`, async () => {
    const actionContainer = await buildActionImage(scenario.phpImage);
    const { docsOutputPath, workspacePath } = await runAction(actionContainer, "", scenario.phpDocumentorVersion);

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
}
