#include <sourcemod>

// ====[ DEFINES ]=============================================================
#define PLUGIN_VERSION "1.1"

// ====[ PLUGIN ]==============================================================
public Plugin:myinfo =
{
	name = "Flag Targeting",
	author = "ReFlexPoison",
	description = "Creates custom target filters for each admin flag",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
}

// ====[ FUNCTIONS ]==============================================================
public OnPluginStart()
{
	CreateConVar("sm_flagtargeting_version", PLUGIN_VERSION, "Version of Flag Targeting", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	AddMultiTargetFilter("@aflags", AFlagGroup, "all a flagged admins", false);
	AddMultiTargetFilter("@!aflags", noAFlagGroup, "all but a flagged admins", false);

	AddMultiTargetFilter("@bflags", BFlagGroup, "all b flagged admins", false);
	AddMultiTargetFilter("@!bflags", noBFlagGroup, "all but b flagged admins", false);

	AddMultiTargetFilter("@cflags", CFlagGroup, "all c flagged admins", false);
	AddMultiTargetFilter("@!cflags", noCFlagGroup, "all but c flagged admins", false);

	AddMultiTargetFilter("@dflags", DFlagGroup, "all d flagged admins", false);
	AddMultiTargetFilter("@!dflags", noDFlagGroup, "all but d flagged admins", false);

	AddMultiTargetFilter("@eflags", EFlagGroup, "all e flagged admins", false);
	AddMultiTargetFilter("@!eflags", noEFlagGroup, "all but e flagged admins", false);

	AddMultiTargetFilter("@fflags", FFlagGroup, "all f flagged admins", false);
	AddMultiTargetFilter("@!fflags", noFFlagGroup, "all but f flagged admins", false);

	AddMultiTargetFilter("@gflags", GFlagGroup, "all g flagged admins", false);
	AddMultiTargetFilter("@!gflags", noGFlagGroup, "all but g flagged admins", false);

	AddMultiTargetFilter("@hflags", HFlagGroup, "all h flagged admins", false);
	AddMultiTargetFilter("@!hflags", noHFlagGroup, "all but h flagged admins", false);

	AddMultiTargetFilter("@iflags", IFlagGroup, "all i flagged admins", false);
	AddMultiTargetFilter("@!iflags", noIFlagGroup, "all but i flagged admins", false);

	AddMultiTargetFilter("@jflags", JFlagGroup, "all j flagged admins", false);
	AddMultiTargetFilter("@!jflags", noJFlagGroup, "all but j flagged admins", false);

	AddMultiTargetFilter("@kflags", KFlagGroup, "all k flagged admins", false);
	AddMultiTargetFilter("@!kflags", noKFlagGroup, "all but k flagged admins", false);

	AddMultiTargetFilter("@lflags", LFlagGroup, "all l flagged admins", false);
	AddMultiTargetFilter("@!lflags", noLFlagGroup, "all but l flagged admins", false);

	AddMultiTargetFilter("@mflags", MFlagGroup, "all m flagged admins", false);
	AddMultiTargetFilter("@!mflags", noMFlagGroup, "all but m flagged admins", false);

	AddMultiTargetFilter("@nflags", NFlagGroup, "all n flagged admins", false);
	AddMultiTargetFilter("@!nflags", noNFlagGroup, "all but n flagged admins", false);

	AddMultiTargetFilter("@oflags", OFlagGroup, "all o flagged admins", false);
	AddMultiTargetFilter("@!oflags", noOFlagGroup, "all but o flagged admins", false);

	AddMultiTargetFilter("@pflags", PFlagGroup, "all p flagged admins", false);
	AddMultiTargetFilter("@!pflags", noPFlagGroup, "all but p flagged admins", false);

	AddMultiTargetFilter("@qflags", QFlagGroup, "all q flagged admins", false);
	AddMultiTargetFilter("@!qflags", noQFlagGroup, "all but q flagged admins", false);

	AddMultiTargetFilter("@rflags", RFlagGroup, "all r flagged admins", false);
	AddMultiTargetFilter("@!rflags", noRFlagGroup, "all but r flagged admins", false);

	AddMultiTargetFilter("@sflags", SFlagGroup, "all s flagged admins", false);
	AddMultiTargetFilter("@!sflags", noSFlagGroup, "all but s flagged admins", false);

	AddMultiTargetFilter("@tflags", TFlagGroup, "all t flagged admins", false);
	AddMultiTargetFilter("@!tflags", noTFlagGroup, "all but t flagged admins", false);

	AddMultiTargetFilter("@zflags", ZFlagGroup, "all z flagged admins", false);
	AddMultiTargetFilter("@!zflags", noZFlagGroup, "all but z flagged admins", false);
}

public bool:AFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_RESERVATION))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noAFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_RESERVATION))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:BFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_GENERIC))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noBFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_GENERIC))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:CFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_KICK))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noCFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_KICK))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:DFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_BAN))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noDFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_BAN))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:EFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_UNBAN))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noEFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_UNBAN))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:FFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_SLAY))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noFFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_SLAY))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:GFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_CHANGEMAP))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noGFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_CHANGEMAP))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:HFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_CONVARS))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noHFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_CONVARS))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:IFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_CONFIG))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noIFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_CONFIG))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:JFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_CHAT))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noJFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_CHAT))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:KFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_VOTE))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noKFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_VOTE))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:LFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_PASSWORD))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noLFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_PASSWORD))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:MFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_RCON))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noMFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_RCON))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:NFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_CHEATS))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noNFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_CHEATS))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:OFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_CUSTOM1))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noOFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_CUSTOM1))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:PFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_CUSTOM2))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noPFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_CUSTOM2))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:QFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_CUSTOM3))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noQFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_CUSTOM3))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:RFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_CUSTOM4))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noRFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_CUSTOM4))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:SFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_CUSTOM5))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noSFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_CUSTOM5))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:TFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_CUSTOM6))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noTFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_CUSTOM6))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:ZFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(DoesUserHaveFlag(i, ADMFLAG_ROOT))
			PushArrayCell(hClients, i);
	}
	return true;
}

public bool:noZFlagGroup(const String:strPattern[], Handle:hClients)
{
	for(new i = 1; i <= MaxClients; i ++) if(IsValidClient(i))
	{
		if(!DoesUserHaveFlag(i, ADMFLAG_ROOT))
			PushArrayCell(hClients, i);
	}
	return true;
}

// ====[ STOCKS ]==============================================================
stock bool:IsValidClient(iClient, bool:bReplay = true)
{
	if(iClient <= 0 || iClient > MaxClients)
		return false;
	if(!IsClientInGame(iClient))
		return false;
	if(bReplay && (IsClientSourceTV(iClient) || IsClientReplay(iClient)))
		return false;
	return true;
}

stock bool:DoesUserHaveFlag(iClient, iFlag)
{
	new AdminId:iAdmin = GetUserAdmin(iClient);
	if(iAdmin != INVALID_ADMIN_ID)
	{
		if(GetUserFlagBits(iClient) & iFlag)
			return true;
	}
	return false;
}