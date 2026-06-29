#include <sourcemod>
 
#define PLUGIN_VERSION "0.6.1"
public Plugin:myinfo = {
    name = "Infinite Ammo",
    author = "twistedeuphoria, Darkthrone, Andrej",
    description = "Gives players infinite ammo.",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=55381"
};

new ammo[128];

new activeoffset = 1896
new clipoffset = 1204
new secondclipoffset = 1208;
new maxclients = 0;

new Handle:enablecvar;

public OnPluginStart()
{
    LoadTranslations("common.phrases")
    enablecvar = CreateConVar("sm_iammo_enable", "1", "<0|1|2> 0 = disable infinite ammo; 1 = enable infinite ammo command; 2 = automatically give infinite ammo to everyone");
    CreateConVar("sm_iammo_version", PLUGIN_VERSION, "Infinite Ammo Version", FCVAR_REPLICATED|FCVAR_NOTIFY);
    HookConVarChange(enablecvar, EnableChanged);
    RegAdminCmd("sm_iammo",unlimit, ADMFLAG_KICK,"<user id | name> <0|1> - Gives or removes infinite ammo from a player.", "",0);

    new off = FindSendPropInfo("CAI_BaseNPC", "m_hActiveWeapon");
    if(off != -1) activeoffset = off;

    off = -1;   
    off = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
    if(off != -1) clipoffset = off;
    
    // the same thing as with m_iClip1 does not work with m_iClip2 for some reason
    // so we use m_iSecondaryAmmoType workaround
    off = -1;
    off = FindSendPropInfo("CBaseCombatWeapon", "m_iSecondaryAmmoType");
    if(off != -1) secondclipoffset = off;
}

public OnMapStart() {
    maxclients = MaxClients;
}

public EnableChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if(convar == enablecvar)
    {
        new oldval = StringToInt(oldValue);
        new newval = StringToInt(newValue);
        
        if(newval == oldval) return;
        
        if( (newval != 0) && (newval != 1) && (newval != 2) )
        {
            PrintToServer("%s is not a valid value for sm_iammo_enable, switching back to %s", newValue, oldValue);
            SetConVarInt(enablecvar, oldval);
        }
        else
        {
        
            if(oldval == 2) 
            {
                PrintToChatAll("Infinite ammo for everyone removed!");
                for(new i=1;i<maxclients;i++)
                {
                    if(IsValidEntity(i) && IsClientConnected(i))
                    {
                        ammo[i] = 0;
                    }
                }
            }
        
            if(newval == 2)
            {
                PrintToChatAll("Infinite ammo enabled for everyone!");
                for(new i=1;i<maxclients;i++)
                {
                    if(IsValidEntity(i) && IsClientConnected(i))
                    {
                        ammo[i] = 1;
                    }
                }
            }
        }
    }
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
    if(GetConVarInt(enablecvar) == 2)
    {
        ammo[client] = 1;
    }
    
    return true;
}

public OnClientDisconnect(client)
{
    ammo[client] = 0;
}

public Action:unlimit(client,args)
{

    new curval = GetConVarInt(enablecvar);
    
    if(curval == 0)
    {
        PrintToConsole(client, "Infinite Ammo is currently disabled.");
        return Plugin_Handled;
    }

    new aid = client;
    if(args != 2)
    {
        PrintToConsole(aid, "Proper Usage: <user id | name> <0|1>");
        return Plugin_Handled;
    }
    new String:idstr[50];
    GetCmdArg(1,idstr,50);
    new String:switchstr[2];
    GetCmdArg(2,switchstr,2);
    
    int targets[1];
    char tgtname[50];
    bool ml;
    
    if(ProcessTargetString(idstr, client, targets, 1, 0, tgtname, 50, ml) != 1)
    {
        PrintToConsole(client, "Target not found.");
        return Plugin_Handled;
    }
    
    new onoff = StringToInt(switchstr);
    ammo[targets[0]] = onoff;
//  new String:name[50]
//  GetClientName(id, name, 50);
    if(onoff)
    {
        PrintToConsole(aid,"%s was given infinite ammo.",tgtname);
        PrintToConsole(targets[0], "You were given infinite ammo.");
    }
    else
    {
        PrintToConsole(aid,"%s had their infinite ammo removed.",tgtname);
        PrintToConsole(targets[0],"You're infinite ammo was removed.");
    }
    return Plugin_Handled;
}

public OnGameFrame()
{
    new iWeapon;
    new iSecondAmmo;
    for(new iClient=1;iClient<=maxclients;iClient++)
    {
        if( (ammo[iClient] == 1) && IsClientInGame(iClient))
        {
            iWeapon = GetEntDataEnt2(iClient, activeoffset);
            if(IsValidEntity(iWeapon)) {
                SetEntData(iWeapon, clipoffset, 50, 4, true);
                iSecondAmmo = GetEntData(iWeapon, secondclipoffset, 1);
                if (iSecondAmmo != 255)
                    SetEntProp(iClient, Prop_Send, "m_iAmmo", 5, _, iSecondAmmo);
            }
        }
    }
}