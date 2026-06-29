#include <sdkhooks>

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamagePre);
}

public Action:OnTakeDamagePre(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3], damagecustom)
{
    if (damagetype & DMG_BLAST) {
        // use these three in case something goes wrong (such as this not working)
        // the command will change the player's DSP to the ear bleeding noise you get from blast damage in HL2.
        ClientCommand(victim, "dsp_player 36");
        FakeClientCommand(victim, "dsp_player 36");
        FakeClientCommandEx(victim, "dsp_player 36");
    }
    return Plugin_Changed;
}