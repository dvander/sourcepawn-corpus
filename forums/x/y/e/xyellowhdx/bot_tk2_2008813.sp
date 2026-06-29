#include <botattackcontrol>
#include <sourcemod>
public Action:OnShouldBotAttackPlayer(bot, player, &bool:result)
{
    result = true;
    return Plugin_Changed;
}  