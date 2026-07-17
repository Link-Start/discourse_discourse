import Component from "@glimmer/component";
import { on } from "@ember/modifier";
import { action } from "@ember/object";

export default class IntegerSettingField extends Component {
  @action
  preventDecimal(event) {
    if (event.key === "." || event.key === ",") {
      event.preventDefault();
    }
  }

  <template>
    <@field.Control
      min={{@definition.min}}
      max={{@definition.max}}
      {{on "keydown" this.preventDecimal}}
    />
  </template>
}
