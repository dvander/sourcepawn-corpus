#include <botattackcontrol>
public Action:OnShouldBotAttackPlayer(bot, player, &bool:result)
{
    result = true;
    return Plugin_Changed;
}  