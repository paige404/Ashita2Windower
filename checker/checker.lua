--[[
* Ashita - Copyright (c) 2014 - 2017 atom0s [atom0s@live.com]
*
* This work is licensed under the Creative Commons Attribution-NonCommercial-NoDerivatives 4.0 International License.
* To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-nd/4.0/ or send a letter to
* Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
*
* By using Ashita, you agree to the above license and its terms.
*
*      Attribution - You must give appropriate credit, provide a link to the license and indicate if changes were
*                    made. You must do so in any reasonable manner, but not in any way that suggests the licensor
*                    endorses you or your use.
*
*   Non-Commercial - You may not use the material (Ashita) for commercial purposes.
*
*   No-Derivatives - If you remix, transform, or build upon the material (Ashita), you may not distribute the
*                    modified material. You are, however, allowed to submit the modified works back to the original
*                    Ashita project in attempt to have it added to the original project.
*
* You may not apply legal terms or technological measures that legally restrict others
* from doing anything the license permits.
*
* No warranties are given.
]]--

_addon.author   = 'atom0s & Lolwutt, adapted by paige_404';
_addon.name     = 'Checker';
_addon.version  = '3.0.0';

require('tables')
packets = require('packets')

---------------------------------------------------------------------------------------------------
-- Constants
---------------------------------------------------------------------------------------------------
PACKET_IDS = {
    ZONE_CHANGE_PACKET = 0x000A,
    BASIC_MESSAGE_PACKET = 0x0029,
    WIDESCAN_RESULT_PACKET = 0x00F4,
}

MESSAGES = {
    IMPOSSIBLE = 0xF9,
}

SPECIAL_CHARACTERS = {
    ARROW = string.char(0x81, 0xA8),
}

CHAT_MODES = {
    SYSTEM_MESSAGES = 121,
}

---------------------------------------------------------------------------------------------------
-- Check Condition Table
---------------------------------------------------------------------------------------------------
local defenses_table =
{
    { 0xAA, '\31\200(\31\130High Evasion, High Defense\31\200)'},
    { 0xAB, '\31\200(\31\130High Evasion\31\200)' },
    { 0xAC, '\31\200(\31\130High Evasion, Low Defense\31\200)' },
    { 0xAD, '\31\200(\31\130High Defense\31\200)' },
    { 0xAE, '' },
    { 0xAF, '\31\200(\31\130Low Defense\31\200)' },
    { 0xB0, '\31\200(\31\130Low Evasion, High Defense\31\200)' },
    { 0xB1, '\31\200(\31\130Low Evasion\31\200)' },
    { 0xB2, '\31\200(\31\130Low Evasion, Low Defense\31\200)' },
};

---------------------------------------------------------------------------------------------------
-- Check Type Table
---------------------------------------------------------------------------------------------------
local comparison_table =
{
    { 0x40, '\30\02too weak to be worthwhile' },
    { 0x41, '\30\02like incredibly easy prey' },
    { 0x42, '\30\02like easy prey' },
    { 0x43, '\30\102like a decent challenge' },
    { 0x44, '\30\08like an even match' },
    { 0x45, '\30\68tough' },
    { 0x46, '\30\76very tough' },
    { 0x47, '\30\76incredibly tough' }
};

---------------------------------------------------------------------------------------------------
-- Widescan Storage Data
---------------------------------------------------------------------------------------------------
local widescan = { };

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Called when our addon receives an incoming packet.
---------------------------------------------------------------------------------------------------
windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    -- Zone Change Packet
    if (id == PACKET_IDS.ZONE_CHANGE_PACKET) then
        -- Reset the widescan data..
        widescan = { };
        return false;
    end

    -- Message Basic Packet
    if (id == PACKET_IDS.BASIC_MESSAGE_PACKET) then
        local parsed = packets.parse('incoming', original)
        local level = parsed['Param 1']; -- Monster Level
        local comparison = parsed['Param 2']; -- Check Type
        local defenses = parsed.Message; -- Defense and Evasion

        local comparison_string = nil;
        local defense_string = nil;

        -- Obtain the check type and condition string..
        for k, v in pairs(comparison_table) do
            if (v[1] == comparison) then
                comparison_string = v[2];
            end
        end
        for k, v in pairs(defenses_table) do
            if (v[1] == defenses) then
                defense_string = v[2];
            end
        end

        -- Check for impossible to gauge..
        if (defenses == MESSAGES.IMPOSSIBLE) then
            comparison_string = '';
            defense_string = '';
        end

        -- Ensure a check type and condition was found..
        if (comparison_string == nil or defense_string == nil) then
            return false;
        end

        -- Obtain the target entity..
        local target = parsed.Target;
        local entity = windower.ffxi.get_mob_by_id(target);
        if (entity == nil) then
            return false;
        end

        -- Check the level for overrides from widescan..
        if (level <= 0) then
            local widescan_level = widescan[target];
            if (widescan_level ~= nil) then
                level = widescan_level;
            end
        end

        -- Print out based on NM or not..
        if (defenses == MESSAGES.IMPOSSIBLE) then
            local level_string = '???';
            if (level > 0) then
                level_string = tostring(level);
            end
            windower.add_to_chat(
                    CHAT_MODES.SYSTEM_MESSAGES,
                    string.format(
                            '\31\200[\30\82checker\31\200] \31\130%s \30\82%s\31\130 \31\200(Lv. \30\82%s\31\200) \30\05Impossible to gauge!',
                            entity.name, SPECIAL_CHARACTERS.ARROW, level_string)
            );
        else
            windower.add_to_chat(
                    CHAT_MODES.SYSTEM_MESSAGES,
                    string.format(
                            '\31\200[\30\82checker\31\200] \31\130%s \30\82%s\31\130 \31\200(Lv. \30\82%d\31\200) \31\130Seems %s\31\130. %s',
                            entity.name, SPECIAL_CHARACTERS.ARROW, level, comparison_string, defense_string)
            );
        end

        return true;
    end

    -- Widescan Result Packet
    if (id == PACKET_IDS.WIDESCAN_RESULT_PACKET) then
        local parsed = packets.parse('incoming', original)
        local index = parsed.Target; -- Entity Index
        local level = parsed.Level; -- Entity Level
        
        -- Store the index and level information..
        widescan[index] = level;
        return false;
    end

    return false;
end);