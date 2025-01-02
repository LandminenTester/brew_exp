Config = {}
Config.Debug = false

--[[ 
If you use VORP, then set to true. If you can replace every exp sets from vorp with my exp system exports, because 
in vorp skills there is no way to get the exp to transfer if you level up. So if their 5 exp missing to level up to level 2, 
but you get 10 exp. You will level up to Level 2 and the extra 5 exp will be lost. With my exp system the exp will be added to the next level. 
This will minimize the complaints of people losing exp because they are missing just a few exp but got from a action alot of exp.
]]
Config.UseVorpSkills = false

Config.Skills = {
    drugs = { -- Name of the Skill Name
        Levels = {
            { -- level 1
                NextLevel = 100, -- if 100 xp is reached then level up, this is the max xp for this level
                Label = "Beginner"
            }, { -- level 2
                NextLevel = 200, -- need to have 200 xp to level up
                Label = "Novice"
            }, { -- level 3
                NextLevel = 300, -- need to have 300 xp to level up
                Label = "Apprentice"
            }, { -- level 4
                NextLevel = 400, -- need to have 400 xp to level up
                Label = "Journeyman"
            }, { -- level 5
                NextLevel = 500, -- need to have 500 xp to level up
                Label = "Expert"
            }
        }
    },

    mining = { -- Name of the Skill Name
        Levels = {
            { -- level 1
                NextLevel = 100, -- if 100 xp is reached then level up, this is the max xp for this level
                Label = "Beginner"
            }, { -- level 2
                NextLevel = 200, -- need to have 200 xp to level up
                Label = "Novice"
            }, { -- level 3
                NextLevel = 300, -- need to have 300 xp to level up
                Label = "Apprentice"
            }, { -- level 4
                NextLevel = 400, -- need to have 400 xp to level up
                Label = "Journeyman"
            }, { -- level 5
                NextLevel = 500, -- need to have 500 xp to level up
                Label = "Expert"
            }
        }
    },

    Hunting = { -- Name of the Skill Name
        Levels = {
            { -- level 1
                NextLevel = 100, -- if 100 xp is reached then level up, this is the max xp for this level
                Label = "Beginner"
            }, { -- level 2
                NextLevel = 200, -- need to have 200 xp to level up
                Label = "Novice"
            }, { -- level 3
                NextLevel = 300, -- need to have 300 xp to level up
                Label = "Apprentice"
            }, { -- level 4
                NextLevel = 400, -- need to have 400 xp to level up
                Label = "Journeyman"
            }, { -- level 5
                NextLevel = 500, -- need to have 500 xp to level up
                Label = "Expert"
            }
        }
    },

}

