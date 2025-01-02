# Brew EXP: Enhanced Skill and Experience API
Brew EXP is a flexible, cross-framework API designed to manage and enhance experience and skill systems. Whether you're working with VORP or another framework, this API provides easy integration and customization options for your server-side skill systems.

It’s fully open-source, giving you full access to the code, so you can refine and extend the API to meet your needs. Enable seamless support for skills across frameworks and get started with a simple configuration.

Get support on my discord: https://discord.gg/sZKg6kEC2Y
## Features:

- Easy integration with any framework
- Supports VORP skills data
- Fully open-source and customizable
- Server-side only

##Exports:

### getMissingExp()
```lua
---@param source integer The source ID of the user
---@param category string The skill category
exports.brew_exp:getMissingExp(source, category) --returns the missing exp to level up
```
### getSkillLevel()
```lua
---@param source integer The source ID of the user
---@param category string The skill category
exports.brew_exp:getSkillLevel(source, category) --returns the current skill level
```
### getSkillExp()
```lua
---@param source integer The source ID of the user
---@param category string The skill category
exports.brew_exp:getSkillExp(source, category) --returns the current skill exp
```
### addSkillExp()
```lua
---@param source integer The source ID of the user
---@param category string The skill category
---@param expToAdd number The amount of experience to add
exports.brew_exp:addSkillExp(source, category, amount) --add exp to a skill and when reaching maxexp for the level it levels up
```
### removeSkillExp()
```lua
---@param source integer The source ID of the user
---@param category string The skill category
---@param expToRemove number The amount of experience to remove
exports.brew_exp:removeSkillExp(source, category, amount) -- (Only Usable without Vorp Skills) - Remove exp from skill and decrease the level if hitting 0
```
### setSkillLevel()
```lua
---@param source integer The source ID of the user
---@param category string The skill category
---@param level integer The level to set
---@param resetExp boolean Whether to reset experience
exports.brew_exp:setSkillLevel(source, category, level, resetexp) -- (Only Usable without Vorp Skills) - Change the level of a skill to a set level and set in resetexp a true/false if the exp should go to 0
```
### getSkill()
```lua
---@param source integer The source ID of the user
---@param category string The skill category
exports.brew_exp:getSkill(source, category) --get all values of a skill
```
### getSkills()
```lua
---@param source integer The source ID of the user
exports.brew_exp:getSkills(source) -- get all skills and their values
```
### getSkillConfig()
```lua
---@param category string The skill category
exports.brew_exp:getSkillConfig(category) --get the config settings of a category
```
### getSkillLabel()
```lua
---@param source integer The source ID of the user
---@param category string The skill category
exports.brew_exp:getSkillLabel(source, category) -- get the label of the current skill level the player has
```
