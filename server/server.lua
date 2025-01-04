-------------------------------------------------------------------------------------------
------------------------------- Brew exp System - Server Main --------------------------------
-------------------------------------------------------------------------------------------
local UserStorage = {}

RegisterNetEvent("brew_exp:getUserData")
AddEventHandler("brew_exp:getUserData", function()
    if Config.UseVorpSkills == false then
        local skills = MySQL.query.await("SELECT * FROM brew_exp")
        for _, skill in pairs(skills) do
            UserStorage[skill.charid] = skill.skills
        end
    end
end)

function getSkillConfig(category)
    if Config.Skills[category] then
        return Config.Skills[category]
    else
        print("Skill category does not exist, please create in config.lua")
        return nil
    end
end
exports('getSkillConfig', getSkillConfig)

---@param source integer The source ID of the user
function getSkills(source)
    if Config.UseVorpSkills then
        local VORPcore = exports.vorp_core:GetCore()
        local Character = VORPcore.getUser(source).getUsedCharacter
        local skills = Character.skills
        return json.encode(skills)
    else
        local user = jo.framework:getUser(source)
        local data = user:getIdentifiers()
        return UserStorage[data.charid]
    end
end
exports('getSkills', getSkills)

---@param source integer The source ID of the user
---@param category string The skill category
function getSkill(source, category)
    if Config.UseVorpSkills then
        local VORPcore = exports.vorp_core:GetCore()
        local Character = VORPcore.getUser(source).getUsedCharacter
        local skills = Character.skills
        if skills[category] then
            return json.encode(skills[category])
        else
            return nil
        end
    else
        local user = jo.framework:getUser(source)
        local data = user:getIdentifiers()
        local skills = json.decode(UserStorage[data.charid])
        if skills[category] then
            return json.encode(skills[category])
        else
            return nil
        end
    end
end
exports('getSkill', getSkill)

---@param source integer The source ID of the user
---@param category string The skill category
---@param expToRemove number The amount of experience to remove
function removeSkillExp(source, category, expToRemove)
    local _source = source
    if expToRemove <= 0 then
        print("Exp to remove must be greater than 0")
        return
    end

    if Config.UseVorpSkills == false then
        local user = jo.framework:getUser(source)
        local playerData = user:getIdentifiers()
        local skillsJSON = getSkills(source) -- Assuming this returns a JSON string
        local skills = json.decode(skillsJSON) or {} -- Decode JSON to a table, fallback to empty table if nil
        if (Config.Skills[category] == nil) then
            print("Category does not exist, please create in config.lua")
            return
        end
        
        -- Check if the category exists; if not, add it
        if not skills[category] then
            skills[category] = {
                Exp = 0,
                MaxLevel = #Config.Skills[category].Levels,
                Label = Config.Skills[category].Levels[1].Label,
                NextLevel = Config.Skills[category].Levels[1].NextLevel,
                Level = 1
            }
        end
        print(json.encode(skills[category]))
        -- Remove the EXP from the category
        local skill = skills[category]
        skill.Exp = skill.Exp - expToRemove

        -- Handle level-down logic
        while skill.Exp < 0 and skill.Level > 1 do
            skill.Level = skill.Level - 1
            skill.NextLevel = Config.Skills[category].Levels[skill.Level].NextLevel
            skill.Label = Config.Skills[category].Levels[skill.Level].Label
            skill.Exp = skill.Exp + skill.NextLevel
        end

        -- Ensure EXP doesn't go below 0 for the lowest level
        if skill.Level == 1 and skill.Exp < 0 then
            skill.Exp = 0
        end

        -- Update the skills in the database
        MySQL.update("UPDATE brew_exp SET skills = @skills WHERE charid = @charid", {
            skills = json.encode(skills), -- Encode updated skills back to JSON
            charid = playerData.charid
        })
        UserStorage[playerData.charid] = json.encode(skills)
        print(json.encode(skills[category]))
        return json.encode(skills)
    end
end

---@param source integer The source ID of the user
---@param category string The skill category
---@param expToAdd number The amount of experience to add
function addSkillExp(source, category, expToAdd)
    local _source = source
    if expToAdd <= 0 then
        print("Exp to add must be greater than 0")
        return
    end
    if Config.UseVorpSkills then
        local VORPcore = exports.vorp_core:GetCore() -- NEW includes  new callback system
        local Character = VORPcore.getUser(_source).getUsedCharacter
        local expAmount = expToAdd
        while expAmount > 0 do
            local missingExp = tonumber(getMissingExp(_source, category))
            if missingExp  <= expAmount then
                Character.setSkills(category, missingExp)
                expAmount = expAmount - missingExp
            else
                Character.setSkills(category, expAmount)
                expAmount = 0
            end
        end
    else
        -- Parse the player's skills JSON string into a Lua table
        local user = jo.framework:getUser(source)
        local playerData = user:getIdentifiers()
        local skillsJSON = getSkills(source) -- Assuming this returns a JSON string
        local skills = json.decode(skillsJSON) or {} -- Decode JSON to a table, fallback to empty table if nil
        if (Config.Skills[category] == nil) then
            print("Category does not exist, please create in config.lua")
            return
        end
        -- Check if the category exists; if not, add it
        if not skills[category] then
            skills[category] = {
                Exp = 0,
                MaxLevel = #Config.Skills[category].Levels,
                Label = Config.Skills[category].Levels[1].Label,
                NextLevel = Config.Skills[category].Levels[1].NextLevel,
                Level = 1
            }
        end

        -- Add the EXP to the category
        local skill = skills[category]
        skill.Exp = skill.Exp + expToAdd

        -- Handle level-up logic
        while skill.Exp >= skill.NextLevel and skill.Level < skill.MaxLevel do
            skill.Exp = skill.Exp - skill.NextLevel
            skill.Level = skill.Level + 1
            skill.Label = Config.Skills[category].Levels[skill.Level].Label
            skill.NextLevel = Config.Skills[category].Levels[skill.Level].NextLevel
        end

        -- Ensure EXP doesn't exceed NextLevel for the max level
        if skill.Level == skill.MaxLevel and skill.Exp > skill.NextLevel then
            skill.Exp = skill.NextLevel
        end

        -- Update the skills in the database
        MySQL.update("UPDATE brew_exp SET skills = @skills WHERE charid = @charid", {
            skills = json.encode(skills), -- Encode updated skills back to JSON
            charid = playerData.charid
        })
        UserStorage[playerData.charid] = json.encode(skills)

        return json.encode(skills)
    end
end
exports('addSkillExp', addSkillExp)

---@param source integer The source ID of the user
---@param category string The skill category
---@param level integer The level to set
---@param resetExp boolean Whether to reset experience
function setSkillLevel(source, category, level, resetExp)
    local _source = source
    if Config.UseVorpSkills == false then
        -- Parse the player's skills JSON string into a Lua table
        local user = jo.framework:getUser(source)
        local playerData = user:getIdentifiers()
        local skillsJSON = getSkills(source) -- Assuming this returns a JSON string
        local skills = json.decode(skillsJSON) or {} -- Decode JSON to a table, fallback to empty table if nil
        if (Config.Skills[category] == nil) then
            print("Category does not exist, please create in config.lua")
            return
        end
        -- Check if the category exists; if not, add it
        if not skills[category] then
            skills[category] = {
                Exp = 0,
                MaxLevel = #Config.Skills[category].Levels,
                Label = Config.Skills[category].Levels[1].Label,
                NextLevel = Config.Skills[category].Levels[1].NextLevel,
                Level = 1
            }
        end

        -- Add the EXP to the category
        local skill = skills[category]
        skill.Level = level
        
        if resetExp == true then
            skill.Exp = 0
        end

        MySQL.update("UPDATE brew_exp SET skills = @skills WHERE charid = @charid", {
            skills = json.encode(skills), -- Encode updated skills back to JSON
            charid = playerData.charid
        })
        UserStorage[playerData.charid] = json.encode(skills)

        return json.encode(skills)
    end
end
exports('setSkillLevel', setSkillLevel)

---@param source integer The source ID of the user
---@param category string The skill category
function getSkillExp(source, category)
    if Config.UseVorpSkills then
        local VORPcore = exports.vorp_core:GetCore()
        local Character = VORPcore.getUser(source).getUsedCharacter
        local skills = Character.skills
        print(json.encode(skills))
        local skill = skills[category]
        print(json.encode(skill))
        if skill then
            return skill.Exp
        else
            return nil
        end
    else
        local skillsJSON = getSkills(source)
        local skills = json.decode(skillsJSON) or {}

        if skills[category] then
            return skills[category].Exp
        else
            return nil, "Skill category does not exist."
        end
    end
end
exports('getSkillExp', getSkillExp)

---@param source integer The source ID of the user
---@param category string The skill category
function getSkillLevel(source, category)
    if Config.UseVorpSkills then
        local VORPcore = exports.vorp_core:GetCore() -- NEW includes  new callback system
        local Character = VORPcore.getUser(source).getUsedCharacter
        local skills = Character.skills
        local skill = skills[category]
        if skill then
            return skill.Level
        else
            return nil
        end
    else
        -- Get the skills JSON and decode it into a Lua table
        local skillsJSON = getSkills(source)
        local skills = json.decode(skillsJSON) or {}

        -- Check if the category exists and return the level
        if skills[category] then
            return skills[category].Level
        else
            return nil
        end
    end
end
exports('getSkillLevel', getSkillLevel)


---@param source integer The source ID of the user
---@param category string The skill category
function getSkillLabel(source, category)
    if Config.UseVorpSkills then
        local VORPcore = exports.vorp_core:GetCore() -- NEW includes  new callback system
        local Character = VORPcore.getUser(source).getUsedCharacter
        local skills = Character.skills
        local skill = skills[category]
        if skill then
            return skill.Label
        else
            return nil
        end
    else
        -- Get the skills JSON and decode it into a Lua table
        local skillsJSON = getSkills(source)
        local skills = json.decode(skillsJSON) or {}

        -- Check if the category exists and return the level
        if skills[category] then
            return skills[category].Label
        else
            return nil
        end
    end
end
exports('getSkillLabel', getSkillLabel)


---@param source integer The source ID of the user
---@param category string The skill category
function getMissingExp(source, category)
    if Config.UseVorpSkills then
        local VORPcore = exports.vorp_core:GetCore() -- NEW includes  new callback system
        local Character = VORPcore.getUser(source).getUsedCharacter
        local skills = Character.skills
        local skill = skills[category]
        if skill then
            return skill.NextLevel - skill.Exp
        else
            return nil
        end
    else
        local exp = getSkillExp(source, category)
        local nextLevel = Config.Skills[category].Levels[getSkillLevel(source, category)].NextLevel
        return nextLevel - exp
    end
end
exports('getMissingExp', getMissingExp)


