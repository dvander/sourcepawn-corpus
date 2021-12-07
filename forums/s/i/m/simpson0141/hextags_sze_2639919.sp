#include <sourcemod>
#include <hextags>
#include <mostactive>
#include <colorvariables>
#include <SteamWorks>

public Plugin myinfo =
{
	name 			= "Hextags Hotfix",
	author 			= "SHIM",
	description 	= "",
	version 		= "1.0",
	url 			= ""
};

ConVar iGroupID;

#define VIP_ChatTag "{darkred}[VIP] "
#define VIP_NameColor "{default}"
#define VIP_NameColor "{default}"

#define SZE_ChatTag "{grey}[SZE] "
#define SZE_NameColor "{teamcolor}"

#define Star1_Time 180000
#define Star1_ChatTag "{default}[{yellow}★{default}] "
#define Star1_NameColor "{teamcolor}"

#define Star2_Time 360000
#define Star2_ChatTag "{default}[{yellow}★★{default}] "
#define Star2_NameColor "{teamcolor}"

#define Star3_Time 540000
#define Star3_ChatTag "{default}[{gold}★★★{default}] "
#define Star3_NameColor "{teamcolor}"

#define Star4_Time 720000
#define Star4_ChatTag "{default}[{orchid}★★★★{default}] "
#define Star4_NameColor "{teamcolor}"

bool b_IsMember[MAXPLAYERS+1];

#define LoopAllPlayers(%1) for(int %1=1;%1<=MaxClients;++%1)\
if(IsClientInGame(%1) && !IsFakeClient(%1))

public void OnPluginStart()
{
	iGroupID = CreateConVar("sm_hextags_groupid", "00000000", "Steam Group ID (Replace with yours)");
}

public void OnClientPostAdminCheck(int client)
{
	b_IsMember[client] = false;
	SteamWorks_GetUserGroupStatus(client, GetConVarInt(iGroupID));
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupAccountID, bool isMember, bool isOfficer)
{
	int client = GetUserFromAuthID(authid);

	if (isMember) b_IsMember[client] = true;
}

int GetUserFromAuthID(int authid)
{
	LoopAllPlayers(i)
	{
		char authstring[50], authstring2[50];
		GetClientAuthId(i, AuthId_Steam3, authstring, sizeof(authstring)); 
		IntToString(authid, authstring2, sizeof(authstring2));

		if (StrContains(authstring, authstring2) != -1)
		{
			return i;
		}
	}
	return -1;
}

public void HexTags_OnTagsUpdated(int client)
{
	if (b_IsMember[client])
	{
		HexTags_SetClientTag(client, ChatTag, SZE_ChatTag);
		HexTags_SetClientTag(client, NameColor, SZE_NameColor);
	}
	if (GetUserFlagBits(client) & ADMFLAG_RESERVATION)
	{
		HexTags_SetClientTag(client, ChatTag, VIP_ChatTag);
		HexTags_SetClientTag(client, NameColor, VIP_NameColor);
		HexTags_SetClientTag(client, NameColor, VIP_NameColor);
	}
	else if (MostActive_GetPlayTimeTotal(client) >= Star4_Time)
	{
		HexTags_SetClientTag(client, ChatTag, Star4_ChatTag);
		HexTags_SetClientTag(client, NameColor, Star4_NameColor);
	}
	else if (MostActive_GetPlayTimeTotal(client) >= Star3_Time)
	{
		HexTags_SetClientTag(client, ChatTag, Star3_ChatTag);
		HexTags_SetClientTag(client, NameColor, Star3_NameColor);
	}
	else if (MostActive_GetPlayTimeTotal(client) >= Star2_Time)
	{
		HexTags_SetClientTag(client, ChatTag, Star2_ChatTag);
		HexTags_SetClientTag(client, NameColor, Star2_NameColor);
	}
	else if (MostActive_GetPlayTimeTotal(client) >= Star1_Time)
	{
		HexTags_SetClientTag(client, ChatTag, Star1_ChatTag);
		HexTags_SetClientTag(client, NameColor, Star1_NameColor);
	}
}