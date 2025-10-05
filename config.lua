Config = {}

-- General Settings
Config.Debug = false
Config.ExplosiveItem = 'tnt' -- Item required to blow up safes/vaults
Config.RobberyTimeout = 30000 -- Time in ms to complete robbery after starting
Config.CooldownTime = 3600000 -- 60 minutes cooldown between robberies (in ms)
Config.PoliceRequired = 0 -- Minimum police/lawman required online

-- Loot Settings
Config.Rewards = {
    safe = {
        cash = {min = 50, max = 200},
        gold_bar = {min = 1, max = 3, chance = 30}, -- 30% chance
        diamond = {min = 0, max = 1, chance = 15}   -- 15% chance
    },
    vault = {
        cash = {min = 200, max = 800},
        gold_bar = {min = 2, max = 8, chance = 60}, -- 60% chance  
        diamond = {min = 1, max = 4, chance = 40}   -- 40% chance
    }
}

-- Bank Locations
Config.Banks = {
    valentine = {
        name = "Valentine Bank",
        coords = vector3(-309.00, 763.63, 118.70),
        heading = 0.0,
        blip = {
            sprite = `blip_ambient_bounty_target`,
            scale = 0.8
        },
        vaults = {
            {
                coords = vector3(-309.00, 763.63, 118.70),
                heading = 0.0,
                type = 'vault',
                robbed = false
            }
        }
    },
    rhodes = {
        name = "Rhodes Bank",
        coords = vector3(1287.42, -1314.50, 77.04),
        heading = 0.0,
        blip = {
            sprite = `blip_ambient_bounty_target`,
            scale = 0.8
        },
        vaults = {
            {
                coords = vector3(1287.42, -1314.50, 77.04),
                heading = 90.0,
                type = 'vault',
                robbed = false
            }
        }
    },
    armadillo = {
        name = "Armadillo Bank",
        coords = vector3(-3665.95, -2632.33, -13.59),
        heading = 0.0,
        blip = {
            sprite = `blip_ambient_bounty_target`,
            scale = 0.8
        },
        vaults = {
            {
                coords = vector3(-3665.95, -2632.33, -13.59),
                heading = 0.0,
                type = 'vault',
                robbed = false
            }
        }
    },
    saintdenis = {
        name = "Saint Denis Bank",
        coords = vector3(2644.49, -1306.44, 52.25),
        heading = 0.0,
        blip = {
            sprite = `blip_ambient_bounty_target`,
            scale = 0.8
        },
        vaults = {
            {
                coords = vector3(2644.49, -1306.44, 52.25),
                heading = 0.0,
                type = 'vault',
                robbed = false
            }
        }
    },
	blackwater = {
        name = "Blackwater Bank",
        coords = vector3(-820.08, -1273.85, 43.65),
        heading = 0.0,
        blip = {
            sprite = `blip_ambient_bounty_target`,
            scale = 0.8
        },
        vaults = {
            {
                coords = vector3(-820.08, -1273.85, 43.65),
                heading = 0.0,
                type = 'vault',
                robbed = false
            }
        }
    }
}


Config.ExplosionSettings = {
    explosionType = 'EXPLOSION_DYNAMITE',
    damageScale = 1.0,
    isAudible = true,
    isInvisible = false,
    cameraShake = 1.0
}


Config.explosion = {
    vault = {
        type = 29,
        radius = 20.0,
        shake = 2.0
    },
    door = {
        type = 25,
        radius = 15.0,
        shake = 1.5
    }
}
