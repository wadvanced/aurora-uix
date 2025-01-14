# Pending tasks for v0.x

- [ ] `define` macro for generating views receiving:
  - [ ] Include define with rendering
  - [ ] Evaluate if :form can be used for live view form component
  - [ ] `module` (module): Schema module to be used for gathering field information.
    - [ ] `opts` (Keyword.t()): List of options, the available ones depends on the type of view.
      - [ ]  `template: Module`: Overrides the module that handles the generation.
        By default uses AuroraUixWeb.AuroraTemplate, which is a sophisticated and highly opinionated template.
        There is also the AuroraUixWeb.PhoenixTemplate, which resembles the phoenix ui.
        The template can also be configured, application wide, by adding :aurora_uix, template: Module.
        New templates can be authored.
      - [ ]  `field: (AuroraUix.Field)`: Field to be added to the default list or updated.
      - [ ]  `fields: []`: Fields to be used, overrides the default list.
        The default list is created with all the fields found in the module, excluding
        the redacted fields.
      - [ ]  `actions: [{:top | :bottom, function}]` : Overrides the default list of actions that are displayed at the top or bottom.
      - [ ]  `add_actions: [{:top | :bottom, function}]`: Adds actions to the current list.
      - [ ]  `remove: []`: List of fields to be remove from the list.
        trying to remove non-existing fields will log a warning, but no error will be raised.
      - [ ]  `title: string | :hide`: Title for the view, a :hide value will make it to be ignored.
      - [ ]  `sub_title: string | :hide`: Subtitle for the view, a :hide value will disallow its generation.
      - [ ]  `remove_actions: [function]`: Removes actions from the current list.

- [ ] `field` macro for defining fields.
- [ ] `meta_uix` macro for defining field meta data.
- [ ] `form` macro for defining a form live view component.
- [ ] `ctx` create context, schema macros for generating CRUD and utilities context function.
- [ ] `mix` Task for generating the context, schema, meta and index and show components
