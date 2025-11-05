-------------------------------------------------------------------------------------------
------------------------------- Brew exp System - Server Main --------------------------------
-------------------------------------------------------------------------------------------
local UserStorage = {}


AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
      return
    end
    if Config.UseVorpSkills == false then
        MySQL.update("CREATE TABLE IF NOT EXISTS brew_exp (identifier VARCHAR(50) PRIMARY KEY, skills LONGTEXT)")
        local skills = MySQL.query.await("SELECT * FROM brew_exp")
        if skills == nil then
            return false
        end
        for _, skill in pairs(skills) do
            UserStorage[skill.identifier] = json.decode(skill.skills)
        end
    end
end)

function getSkillConfig(category)
    if Config.Skills[category] then
        return Config.Skills[category]
    else
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
        return skills
    else
        local user = jo.framework:getUser(source)
        if not user then
            return {}
        end
        local data = user:getIdentifiers()
        if not data or not data.identifier then
            return {}
        end
        if UserStorage[data.identifier] then
            -- Validate existing data before returning
            local skills = UserStorage[data.identifier]
            for category, _ in pairs(Config.Skills) do
                validateAndFixSkillData(skills, category)
            end
            return UserStorage[data.identifier]
        else
            UserStorage[data.identifier] = {}
            MySQL.update("INSERT INTO brew_exp (identifier, skills) VALUES (@identifier, @skills)", {
                identifier = data.identifier,
                skills = json.encode(UserStorage[data.identifier])
            })
            return UserStorage[data.identifier]
        end
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
        if not user then
            return nil
        end
        local data = user:getIdentifiers()
        if not data or not data.identifier then
            return nil
        end
        if not UserStorage[data.identifier] then
            return nil
        end
        local skills = UserStorage[data.identifier]
        if type(skills) == "string" then
            skills = json.decode(skills)
        end
        if skills == nil then
            return nil
        end
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
        return
    end

    if Config.UseVorpSkills == false then
        local user = jo.framework:getUser(source)
        if not user then
            return nil
        end
        local playerData = user:getIdentifiers()
        if not playerData or not playerData.identifier then
            return nil
        end
        local charid = playerData.identifier
        local skillsJSON = getSkills(source) -- This returns a table, not a JSON string
        local skills = skillsJSON or {} -- Use directly since getSkills returns a table
        if (Config.Skills[category] == nil) then
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
        else
            -- Validate and fix existing skill data consistency
            local skill = skills[category]
            if skill.Level and skill.Level > 0 and skill.Level <= #Config.Skills[category].Levels then
                -- Update label and NextLevel based on current level to ensure consistency
                skill.Label = Config.Skills[category].Levels[skill.Level].Label
                skill.NextLevel = Config.Skills[category].Levels[skill.Level].NextLevel
                skill.MaxLevel = #Config.Skills[category].Levels
            end
        end
        -- Remove the EXP from the category
        local skill = skills[category]
        skill.Exp = skill.Exp - expToRemove

        -- Handle level-down logic
        while skill.Exp < 0 and skill.Level > 1 do
            skill.Level = skill.Level - 1
            skill.NextLevel = Config.Skills[category].Levels[skill.Level].NextLevel
            skill.Label = Config.Skills[category].Levels[skill.Level].Label
            skill.Exp = skill.Exp + skill.NextLevel
            Wait(0)
        end

        -- Ensure EXP doesn't go below 0 for the lowest level
        if skill.Level == 1 and skill.Exp < 0 then
            skill.Exp = 0
        end

        -- Update the skills in the database
        if not UserStorage[charid] then
            -- If not, create a new entry with default skills
            UserStorage[charid] = {}
            MySQL.update("INSERT INTO brew_exp (identifier, skills) VALUES (@identifier, @skills)", {
                identifier = charid,
                skills = json.encode(UserStorage[charid])
            })
        end
        MySQL.update("UPDATE brew_exp SET skills = @skills WHERE identifier = @identifier", {
            skills = json.encode(skills), -- Encode updated skills back to JSON
            identifier = charid
        })
        UserStorage[charid] = skills -- Store as table, not JSON string
        debugSkillInfo(source, category)
        return skills -- Return table, not JSON string
    end
end

---@param source integer The source ID of the user
---@param category string The skill category
---@param expToAdd number The amount of experience to add
function addSkillExp(source, category, expToAdd)
    local _source = source
    if expToAdd <= 0 then
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
            Wait(0)
        end
    else
        -- Parse the player's skills JSON string into a Lua table
        local user = jo.framework:getUser(source)
        if not user then
            return nil
        end
        local playerData = user:getIdentifiers()
        if not playerData or not playerData.identifier then
            return nil
        end
        local charid = playerData.identifier
        local skillsJSON = getSkills(source) -- This returns a table, not a JSON string
        
        if (Config.Skills[category] == nil) then
            return
        end
        -- Check if the category exists; if not, add it
        if not skillsJSON[category] then
            skillsJSON[category] = {
                Exp = 0,
                MaxLevel = #Config.Skills[category].Levels,
                Label = Config.Skills[category].Levels[1].Label,
                NextLevel = Config.Skills[category].Levels[1].NextLevel,
                Level = 1
            }
        else
            -- Validate and fix existing skill data consistency
            local skill = skillsJSON[category]
            if skill.Level and skill.Level > 0 and skill.Level <= #Config.Skills[category].Levels then
                -- Update label and NextLevel based on current level to ensure consistency
                skill.Label = Config.Skills[category].Levels[skill.Level].Label
                skill.NextLevel = Config.Skills[category].Levels[skill.Level].NextLevel
                skill.MaxLevel = #Config.Skills[category].Levels
            end
        end

        -- Add the EXP to the category
        local skill = skillsJSON[category]
        skill.Exp = skill.Exp + expToAdd

        -- Handle level-up logic
        while skill.Exp >= skill.NextLevel and skill.Level < skill.MaxLevel do
            skill.Exp = skill.Exp - skill.NextLevel
            skill.Level = skill.Level + 1
            skill.Label = Config.Skills[category].Levels[skill.Level].Label
            skill.NextLevel = Config.Skills[category].Levels[skill.Level].NextLevel
            Wait(0)
        end

        -- Ensure EXP doesn't exceed NextLevel for the max level
        if skill.Level == skill.MaxLevel and skill.Exp > skill.NextLevel then
            skill.Exp = skill.NextLevel
        end
        if not UserStorage[charid] then
            -- If not, create a new entry with default skills
            UserStorage[charid] = {}
            MySQL.update("INSERT INTO brew_exp (identifier, skills) VALUES (@identifier, @skills)", {
                identifier = charid,
                skills = json.encode(UserStorage[charid])
            })
        end
        -- Update the skills in the database
        MySQL.update("UPDATE brew_exp SET skills = @skills WHERE identifier = @identifier", {
            skills = json.encode(skillsJSON), -- Encode updated skills back to JSON
            identifier = charid
        })
        UserStorage[charid] = skillsJSON -- Store as table
        debugSkillInfo(source, category)
        return skillsJSON -- Return table
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
        if not user then
            return nil
        end
        local playerData = user:getIdentifiers()
        if not playerData or not playerData.identifier then
            return nil
        end
        local charid = playerData.identifier
        local skillsJSON = getSkills(source) -- This returns a table, not a JSON string
        local skills = skillsJSON or {} -- Use directly since getSkills returns a table
        if (Config.Skills[category] == nil) then
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
        else
            -- Validate and fix existing skill data consistency
            local skill = skills[category]
            if skill.Level and skill.Level > 0 and skill.Level <= #Config.Skills[category].Levels then
                -- Update label and NextLevel based on current level to ensure consistency
                skill.Label = Config.Skills[category].Levels[skill.Level].Label
                skill.NextLevel = Config.Skills[category].Levels[skill.Level].NextLevel
                skill.MaxLevel = #Config.Skills[category].Levels
            end
        end

        -- Set the level
        local skill = skills[category]
        skill.Level = level
        
        -- Update the label and NextLevel for the new level
        if level > 0 and level <= #Config.Skills[category].Levels then
            skill.Label = Config.Skills[category].Levels[level].Label
            skill.NextLevel = Config.Skills[category].Levels[level].NextLevel
        end
        
        if resetExp == true then
            skill.Exp = 0
        end
        if not UserStorage[charid] then
            -- If not, create a new entry with default skills
            UserStorage[charid] = {}
            MySQL.update("INSERT INTO brew_exp (identifier, skills) VALUES (@identifier, @skills)", {
                identifier = charid,
                skills = json.encode(UserStorage[charid])
            })
        end
        MySQL.update("UPDATE brew_exp SET skills = @skills WHERE identifier = @identifier", {
            skills = json.encode(skills), -- Encode updated skills back to JSON
            identifier = charid
        })
        UserStorage[charid] = skills -- Store as table

        debugSkillInfo(source, category)
        return skills -- Return table
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
        local skill = skills[category]
        if skill then
            return skill.Exp
        else
            return nil
        end
    else
        local skills = getSkills(source) -- This returns a table
        if not skills then
            return nil
        end

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
        -- Get the skills table directly
        local skills = getSkills(source) -- This returns a table
        if not skills then
            return nil
        end

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
        -- Get the skills table directly
        local skills = getSkills(source) -- This returns a table
        if not skills then
            return nil
        end

        -- Check if the category exists and return the label
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

---@param skills table The skills table to validate
---@param category string The skill category to validate
function validateAndFixSkillData(skills, category)
    if not skills or not skills[category] or not Config.Skills[category] then
        return false
    end
    
    local skill = skills[category]
    local config = Config.Skills[category]
    
    -- Ensure all required fields exist
    if not skill.Level then skill.Level = 1 end
    if not skill.Exp then skill.Exp = 0 end
    if not skill.MaxLevel then skill.MaxLevel = #config.Levels end
    
    -- Validate level bounds
    if skill.Level < 1 then skill.Level = 1 end
    if skill.Level > #config.Levels then skill.Level = #config.Levels end
    
    -- Update label and NextLevel based on current level
    skill.Label = config.Levels[skill.Level].Label
    skill.NextLevel = config.Levels[skill.Level].NextLevel
    
    -- Validate experience bounds for current level
    if skill.Exp < 0 then skill.Exp = 0 end
    if skill.Exp >= skill.NextLevel and skill.Level < skill.MaxLevel then
        -- Player should have leveled up, fix this
        while skill.Exp >= skill.NextLevel and skill.Level < skill.MaxLevel do
            skill.Exp = skill.Exp - skill.NextLevel
            skill.Level = skill.Level + 1
            skill.Label = config.Levels[skill.Level].Label
            skill.NextLevel = config.Levels[skill.Level].NextLevel
        end
    end
    
    return true
end

-- Debug function to print skill information
function debugSkillInfo(source, category)
    if not Config.Debug then return end
    
    local skills = getSkills(source)
    if skills and skills[category] then
        local skill = skills[category]
        print("DEBUG - Player " .. source .. " - Category: " .. category)
        print("  Level: " .. tostring(skill.Level))
        print("  Exp: " .. tostring(skill.Exp))
        print("  NextLevel: " .. tostring(skill.NextLevel))
        print("  Label: " .. tostring(skill.Label))
        print("  MaxLevel: " .. tostring(skill.MaxLevel))
    end
end

-- Command to fix all player skill data in the database
RegisterCommand("fixskilldata", function(source, args, rawCommand)
    if source ~= 0 then -- Only allow from server console
        print("This command can only be executed from the server console.")
        return
    end
    
    print("Starting skill data validation and repair...")
    local repaired = 0
    
    for identifier, skills in pairs(UserStorage) do
        local needsUpdate = false
        for category, _ in pairs(Config.Skills) do
            if skills[category] then
                local oldData = json.encode(skills[category])
                validateAndFixSkillData(skills, category)
                local newData = json.encode(skills[category])
                if oldData ~= newData then
                    needsUpdate = true
                end
            end
        end
        
        if needsUpdate then
            MySQL.update("UPDATE brew_exp SET skills = @skills WHERE identifier = @identifier", {
                skills = json.encode(skills),
                identifier = identifier
            })
            repaired = repaired + 1
            print("Repaired skill data for player: " .. identifier)
        end
    end
    
    print("Skill data repair completed. Repaired " .. repaired .. " player records.")
end, true)