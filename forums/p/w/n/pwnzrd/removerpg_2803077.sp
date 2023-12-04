#include <sourcemod>
#include <sdktools>

new Handle:CV_REMOVEWEP = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Remove RPG",
};

public OnPluginStart()
{
    HookEvent("player_spawn", EventSpawn);
    CV_REMOVEWEP = CreateConVar("ob_removerpg","1","Removes RPG and RPG ammo on map start");
}

public OnMapStart()
{
    if(GetConVarInt(CV_REMOVEWEP) == 1)
    {
        for(new i = MaxClients+1; i < GetMaxEntities(); i++)
        {
            if(IsValidEntity(i) && IsValidEdict(i))
            {
                decl String:class[256];
                GetEntityClassname(i, class, sizeof(class));
                if(StrEqual(class, "weapon_rpg"))
                {
                    AcceptEntityInput(i, "Kill");
                }
                else if(StrEqual(class, "item_rpg_round"))
                {
                    AcceptEntityInput(i, "Kill");
                }
            }
        }
    }
}

public EventSpawn(Handle:event, const String:name[], bool:Broadcast)
{
    if(GetConVarInt(CV_REMOVEWEP) == 1)
    {
        new Client = GetClientOfUserId(GetEventInt(event, "userid"));
        if(IsClientInGame(Client))
        {
            CreateTimer(0.5, GunTimer, Client);
        }
    }
}

public Action:GunTimer(Handle:Timer, any:Client)
{
    LoseWeapon(Client, false);
    return Plugin_Handled;
}

stock LoseWeapon(Client, bool:OnDeath = false)
{
    if(!IsClientInGame(Client)) return false;

    RemoveWeapons(Client);
    return true;
}

stock RemoveWeapons(Client)
{
    if(!IsClientInGame(Client)) return true;

    //Declare:
    decl Offset;
    decl WeaponId;
    decl String:weaponName[64];

    //Initialize:
    Offset = FindSendPropOffs("CHL2MP_Player", "m_hMyWeapons");

    new MaxGuns = 256;

    //Loop:
    for(new X = 0; X < MaxGuns; X = (X + 4))
    {

        //Initialize:
        WeaponId = GetEntDataEnt2(Client, Offset + X);

        //Valid:
        if(WeaponId > 0)
        {
            GetEntityClassname(WeaponId, weaponName, sizeof(weaponName));
            if(StrEqual(weaponName, "weapon_rpg"))
            {
                RemovePlayerItem(Client, WeaponId);
                RemoveEdict(WeaponId);
            }
        }
    }
    return true;
}