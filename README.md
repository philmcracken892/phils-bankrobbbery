# RSG Bank Robbery Script

A comprehensive bank robbery script for RedM using the RSG-Core framework with ox_lib integration.

## Features

- **Multiple Bank Locations**: Valentine, Rhodes, Strawberry, and Saint Denis banks
- **Explosive Mechanics**: Use dynamite to blow up safes and vaults
- **Dynamic Loot System**: Rewards include cash, gold bars, and diamonds with chance-based spawning
- **Law Enforcement Integration**: Automatic alerts to RSG-Lawman system
- **ox_lib Integration**: Modern UI with menus and notifications
- **Anti-Spam Protection**: Cooldown timers prevent rapid robberies
- **Admin Commands**: Reset cooldowns with admin permissions
- **Configurable Settings**: Easy customization through config file

## Dependencies

- **rsg-core**: RSG Framework
- **ox_lib**: For UI, notifications, and zones
- **rsg-lawman**: For law enforcement notifications
- **oxmysql**: Database operations

## Installation

1. Download and place the `rsg-bankrobbery` folder in your resources directory
2. Add `ensure rsg-bankrobbery` to your server.cfg
3. Make sure all dependencies are installed and running
4. Restart your server

## Configuration

### Items Required
- Make sure you have a `tnt item in your database/items list
- Ensure `gold_bar` and `diamond` items exist in your inventory system

### Bank Locations
The script comes pre-configured with 4 bank locations:
- Valentine Bank
- Rhodes Bank  
- Strawberry Bank
- Saint Denis Bank

Each location has both safes and vaults with different reward tiers.

### Rewards Configuration
```lua
Config.Rewards = {
    safe = {
        cash = {min = 50, max = 200},
        gold_bar = {min = 1, max = 3, chance = 30},
        diamond = {min = 0, max = 1, chance = 15}
    },
    vault = {
        cash = {min = 200, max = 800},
        gold_bar = {min = 2, max = 8, chance = 60},
        diamond = {min = 1, max = 4, chance = 40}
    }
}
```

## Usage

### For Players
1. Obtain dynamite from shops or other players
2. Visit any of the bank locations (marked with blips)
3. Approach a safe or vault and press `E` to interact
4. Select "Place Dynamite" from the menu
5. Get to cover and wait for the explosion
6. Collect the loot quickly before law enforcement arrives

### For Law Enforcement
- Automatic dispatch notifications when robberies begin
- Alert blips appear on the map
- Integration with RSG-Lawman system for enhanced alerts


## Settings

### General Settings
- `Config.ExplosiveItem`: Item required for robberies (default: 'dynamite')
- `Config.RobberyTimeout`: Time limit for completing robbery (30 seconds)
- `Config.CooldownTime`: Cooldown between robberies (30 minutes)
- `Config.PoliceRequired`: Minimum law enforcement required online (2)

### Explosion Settings
- Configurable explosion type, damage, and effects
- Camera shake and visual effects

### Lawman Integration
- Custom dispatch codes
- Alert radius and response times
- Blip customization

## Customization

### Adding New Banks
To add new bank locations, edit the `Config.Banks` table in `config.lua`:



### Modifying Rewards
Adjust the `Config.Rewards` table to change loot amounts and chances.

### Changing Required Items
Modify `Config.ExplosiveItem` to use different items for robberies.

## Troubleshooting

### Common Issues
1. **"Not enough lawmen in the area"**: Ensure at least 2 police/sheriff players are online
2. **"You need dynamite"**: Make sure the player has the required explosive item
3. **No blips showing**: Check that the resource started properly and dependencies are running
4. **Loot not giving**: Verify that the reward items exist in your database

### Debug Mode
Set `Config.Debug = true` in the config file to enable console logging for troubleshooting.

## Support

For issues or questions:
1. Check the console for error messages
2. Verify all dependencies are installed and up to date
3. Ensure database items exist for rewards
4. Check server permissions for admin commands

## Version History

### v1.0.0
- Initial release
- Multiple bank locations
- Explosive mechanics
- Loot system with cash, gold bars, diamonds
- Law enforcement integration
- ox_lib UI integration
- Anti-spam protection

## License


This script is provided as-is for use with RSG Framework servers.
