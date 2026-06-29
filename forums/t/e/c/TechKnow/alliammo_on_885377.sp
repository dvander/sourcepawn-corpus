#include <sourcemod>
 
public Plugin:myinfo = {
    name = "Infinite Ammo",
    author = "twistedeuphoria & TechKnow",
    description = "Gives players infinite ammo.",
    version = "0.4",
    url = "http://sourcemodplugin.14.forumer.com/"
};

#define PLUGIN_VERSION "0.4" 
new activeoffset = 1896
new clipoffset = 1204
new bool:iammo = true;
new aswitch;

public OnPluginStart()
{
    CreateConVar("sm_iammoall_version", PLUGIN_VERSION, "iammoall Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
    RegAdminCmd("sm_aia", Command_Setiammo, ADMFLAG_SLAY);
    new off = FindSendPropOffs("CAI_BaseNPC", "m_hActiveWeapon");
    if(off != -1)
    {
        activeoffset = off;
    }
    off = -1;
    off = FindSendPropOffs("CBaseCombatWeapon", "m_iClip1");
    if(off != -1)
    {
        clipoffset = off;
    }
}

public OnMapEnd()
{
        iammo = true;
}

public Action:Command_Setiammo(client, args)
{
	if (args < 1)
        {
		ReplyToCommand(client, "[SM] Usage: sm_aia <1/0>");
		return Plugin_Handled;
	}
       
	new String:sa[10];
	GetCmdArg(1, sa, sizeof(sa));
        aswitch = StringToInt(sa);
        if(aswitch == 1)
        {
                iammo = true;
	}
        if(aswitch == 0)
        {
                iammo = false;
        }
        return Plugin_Handled;
}


public OnGameFrame()
{
    if (iammo == false)
	{
		return;
	}
    new zomg;
    for (new i=1; i <= GetMaxClients(); i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i))
        {
            zomg = GetEntDataEnt(i, activeoffset);
            SetEntData(zomg, clipoffset, 5, 4, true);
        }
    }
} 