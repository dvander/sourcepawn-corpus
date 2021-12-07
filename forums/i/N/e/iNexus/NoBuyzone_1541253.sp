public Plugin:myinfo = 
{
	name = "No Buyzone",
	author = "iNex",
	description = "Desactivation de la buyzone",
	version = "0.0154B",
	url = "www.daily-studio.com"
}
public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}
//supprime l'entity buyzone
public OnMapStart()
{
	decl String:szClass[65];
    for (new i = MaxClients; i <= GetMaxEntities(); i++)
    {
        if(IsValidEdict(i) && IsValidEntity(i))
        {
            GetEdictClassname(i, szClass, sizeof(szClass));
            if(StrEqual("func_buyzone", szClass))
            {
                RemoveEdict(i);
            }
        }
    } 
}
//desactive l'entity buyzone
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:szClass[65];
    for (new i = MaxClients; i <= GetMaxEntities(); i++)
    {
        if(IsValidEdict(i) && IsValidEntity(i))
        {
            GetEdictClassname(i, szClass, sizeof(szClass));
            if(StrEqual("func_buyzone", szClass))
            {
                RemoveEdict(i);
            }
        }
    } 
}