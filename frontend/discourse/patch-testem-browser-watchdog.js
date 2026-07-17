const BrowserTestRunner = require("testem/lib/runners/browser_test_runner");
const fs = require("fs");

const patchedRunnerClasses = new WeakSet();

function installBrowserWatchdog(
  RunnerClass,
  {
    inactivityTimeout,
    setTimeout: setTimer = setTimeout,
    clearTimeout: clearTimer = clearTimeout,
  }
) {
  if (patchedRunnerClasses.has(RunnerClass)) {
    return;
  }
  patchedRunnerClasses.add(RunnerClass);

  function clearWatchdog(runner) {
    if (runner.browserWatchdogTimer) {
      clearTimer(runner.browserWatchdogTimer);
      runner.browserWatchdogTimer = undefined;
    }
  }

  function scheduleWatchdog(runner) {
    clearWatchdog(runner);
    runner.browserWatchdogTimer = setTimer(() => {
      runner.browserWatchdogTimer = undefined;
      if (runner.finished) {
        return;
      }

      runner.reportResults(
        new Error(
          `Browser made no test progress for ${inactivityTimeout} seconds outside an active test`
        ),
        0
      );
    }, inactivityTimeout * 1000);
  }

  const originalTryAttach = RunnerClass.prototype.tryAttach;
  RunnerClass.prototype.tryAttach = function (browser, id, socket) {
    const result = originalTryAttach.call(this, browser, id, socket);
    if (result === false) {
      return result;
    }

    scheduleWatchdog(this);
    socket.on("tests-start", () => clearWatchdog(this));
    socket.on("test-result", () => scheduleWatchdog(this));
    socket.on("all-test-results", () => clearWatchdog(this));
    socket.on("after-tests-complete", () => clearWatchdog(this));
    socket.on("disconnect", () => clearWatchdog(this));

    return result;
  };

  const originalFinish = RunnerClass.prototype.finish;
  RunnerClass.prototype.finish = function (...args) {
    clearWatchdog(this);
    return originalFinish.apply(this, args);
  };
}

function patchTestemBrowserWatchdog() {
  if (process.env.QUNIT_BROWSER_WATCHDOG !== "1") {
    return;
  }

  installBrowserWatchdog(BrowserTestRunner, {
    inactivityTimeout: parseInt(
      process.env.QUNIT_BROWSER_INACTIVITY_TIMEOUT,
      10
    ),
  });
}

function markBrowserStartFailure(result, markerPath) {
  if (
    markerPath &&
    result.error?.message?.includes("Browser failed to connect within")
  ) {
    fs.writeFileSync(markerPath, "");
    return true;
  }

  return false;
}

module.exports = patchTestemBrowserWatchdog;
module.exports.installBrowserWatchdog = installBrowserWatchdog;
module.exports.markBrowserStartFailure = markBrowserStartFailure;
