import { render, triggerEvent } from "@ember/test-helpers";
import { module, test } from "qunit";
import { setupRenderingTest } from "discourse/tests/helpers/component-test";
import ScrollContainer from "discourse/ui-kit/scroll-container";

async function scrollTo(selector, props) {
  const element = document.querySelector(selector);
  Object.assign(element, props);
  await triggerEvent(element, "scroll");
}

module("Integration | ui-kit | ScrollContainer", function (hooks) {
  setupRenderingTest(hooks);

  test("no buttons when content fits", async function (assert) {
    await render(
      <template>
        <ScrollContainer style="width: 200px; overflow: auto">
          <div style="width: 50px; height: 20px"></div>
        </ScrollContainer>
      </template>
    );

    assert.dom(".scroll-container__btn").doesNotExist();
  });

  test("no buttons when the overflowing axis is not scrollable", async function (assert) {
    await render(
      <template>
        {{! content overflows horizontally but the axis is clipped, not scrollable }}
        <ScrollContainer style="width: 100px; overflow: hidden">
          <div style="width: 500px; height: 20px"></div>
        </ScrollContainer>
      </template>
    );

    assert.dom(".scroll-container__btn").doesNotExist();
  });

  test("horizontal overflow shows the trailing button, then the leading one", async function (assert) {
    await render(
      <template>
        <ScrollContainer style="width: 100px; overflow-x: auto">
          <div style="width: 500px; height: 20px"></div>
        </ScrollContainer>
      </template>
    );

    assert
      .dom(".scroll-container__btn.--right")
      .exists("shows the scroll-right button at the start");
    assert
      .dom(".scroll-container__btn.--left")
      .doesNotExist("hides the scroll-left button at the start");

    const content = document.querySelector(".scroll-container__content");
    await scrollTo(".scroll-container__content", {
      scrollLeft: content.scrollWidth,
    });

    assert
      .dom(".scroll-container__btn.--left")
      .exists("shows the scroll-left button at the end");
    assert
      .dom(".scroll-container__btn.--right")
      .doesNotExist("hides the scroll-right button at the end");
  });

  test("vertical overflow shows the bottom button, then the top one", async function (assert) {
    await render(
      <template>
        <ScrollContainer style="height: 100px; overflow-y: auto">
          <div style="height: 500px; width: 20px"></div>
        </ScrollContainer>
      </template>
    );

    assert
      .dom(".scroll-container__btn.--down")
      .exists("shows the scroll-down button at the top");
    assert
      .dom(".scroll-container__btn.--up")
      .doesNotExist("hides the scroll-up button at the top");

    const content = document.querySelector(".scroll-container__content");
    await scrollTo(".scroll-container__content", {
      scrollTop: content.scrollHeight,
    });

    assert
      .dom(".scroll-container__btn.--up")
      .exists("shows the scroll-up button at the bottom");
    assert
      .dom(".scroll-container__btn.--down")
      .doesNotExist("hides the scroll-down button at the bottom");
  });

  test("applies consumer classes and attributes", async function (assert) {
    await render(
      <template>
        <ScrollContainer
          @wrapperClass="my-wrap"
          @class="my-content"
          @buttonClass="my-btn"
          style="width: 100px; overflow-x: auto"
          data-test="yes"
        >
          <div style="width: 500px; height: 20px"></div>
        </ScrollContainer>
      </template>
    );

    assert
      .dom(".scroll-container.my-wrap")
      .exists("wrapper gets @wrapperClass");
    assert
      .dom(".scroll-container__content.my-content")
      .hasAttribute(
        "data-test",
        "yes",
        "content gets @class and ...attributes"
      );
    assert
      .dom(".scroll-container__btn.my-btn")
      .exists("buttons get @buttonClass");
  });
});
