--[[
* Ashita - Copyright (c) 2014 - 2016 atom0s [atom0s@live.com]
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

_addon.author   = 'atom0s, adapted by paige404';
_addon.name     = 'blumon';
_addon.version  = '3.0.0';

packets = require('packets')
res = require('resources')

PACKET_IDS = {
    BASIC_MESSAGE = 0x29
}

MESSAGE_IDS = {
    BLUE_MAGIC_LEARNED = 419
}

---------------------------------------------------------------------------------------------------
-- func: incoming_packet
-- desc: Event called when the addon is asked to handle an incoming packet.
---------------------------------------------------------------------------------------------------
windower.register_event('incoming chunk', function(id, original, modified, injected, blocked)
    -- Message basic packet..
    if (id == PACKET_IDS.BASIC_MESSAGE) then
        -- Get the message id..
        local parsed = packets.parse('incoming', original)
        
        local msgid = parsed.Message
        if (msgid == MESSAGE_IDS.BLUE_MAGIC_LEARNED) then
            local sender = parsed['Actor Index'];
            local target = parsed['Target Index'];
            local spellId = parsed['Param 1'];
            local player = windower.ffxi.get_player();
            if (sender == target and sender == player.index) then
                local name = res.spells[spellId].en
                if (name == nil) then name = spellId; end
                windower.add_to_chat(121, '\31\130=========================\31\07>>> \30\02Learned a blue spell! \31\200[\31\05' .. tostring(name) .. '\31\200]');
                return true
            end
        end
    end

    return false;
end);