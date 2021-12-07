//-----------------------------------
//---------- include ----------------
//-----------------------------------
#include <sourcemod>
//-----------------------------------
//----------- define ----------------
//-----------------------------------
#define Nk_creat 			"iNex"
#define Nk_Name				"NoBuyZone"
#define Nk_url				"http://zixstyle.netau.net"
#define Nk_version			"1.0A"
#define Nk_desc 			"Désactive les buyzones"
//-----------------------------------
//----------- Private var -----------
//-----------------------------------
new Get_client;
//-----------------------------------
//----------- Public var ------------
//-----------------------------------
public Plugin:myinfo =
{
	name = Nk_Name,
	author = Nk_creat,
	description = Nk_desc,
	version = Nk_version,
	url = Nk_url
};
public OnMapStart()
{
    decl String:Remove[65];
    Get_client = GetMaxEntities();
    for (new i = 64; i <= Get_client; i++)
    {
        if(IsValidEdict(i) && IsValidEntity(i))
        {
            GetEdictClassname(i, Remove, sizeof(Remove));
            if(StrEqual("func_buyzone", Remove))
            {
                RemoveEdict(i);
            }
        }
    } 
}

