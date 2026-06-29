#include <sourcemod>
#include <sdktools>
#include <dhooks>
/*

	Player.h
	// Observer functions
	virtual bool			StartObserverMode(int mode); // true, if successful
	virtual void			StopObserverMode( void );	// stop spectator mode
	virtual bool			ModeWantsSpectatorGUI( int iMode ) { return true; }
	virtual bool			SetObserverMode(int mode); // sets new observer mode, returns true if successful
	virtual int				GetObserverMode( void ); // returns observer mode or OBS_NONE
	virtual bool			SetObserverTarget(CBaseEntity * target);
	virtual void			ObserverUse( bool bIsPressed ); // observer pressed use
	virtual CBaseEntity		*GetObserverTarget( void ); // returns players targer or NULL
	virtual CBaseEntity		*FindNextObserverTarget( bool bReverse ); // returns next/prev player to follow or NULL
	virtual int				GetNextObserverSearchStartPoint( bool bReverse ); // Where we should start looping the player list in a FindNextObserverTarget call
	virtual bool			IsValidObserverTarget(CBaseEntity * target); // true, if player is allowed to see this target
	virtual void			CheckObserverSettings(); // checks, if target still valid (didn't die etc)
	virtual void			JumptoPosition(const Vector &origin, const QAngle &angles);
	virtual void			ForceObserverMode(int mode); // sets a temporary mode, force because of invalid targets
	virtual void			ResetObserverMode(); // resets all observer related settings
	virtual void			ValidateCurrentObserverTarget( void ); // Checks the current observer target, and moves on if it's not valid anymore
	virtual void			AttemptToExitFreezeCam( void );
*/

new Handle:hStartObserverMode;
new Handle:hStopObserverMode;
new Handle:hModeWantsSpectatorGUI;
new Handle:hSetObserverMode;
new Handle:hGetObserverMode;
new Handle:hSetObserverTarget;
new Handle:hObserverUse;
new Handle:hGetObserverTarget;
new Handle:hFindNextObserverTarget;
new Handle:hGetNextObserverSearchStartPoint;
new Handle:hIsValidObserverTarget;
new Handle:hCheckObserverSettings;
new Handle:hJumptoPosition;
new Handle:hForceObserverMode;
new Handle:hResetObserverMode;
new Handle:hValidateCurrentObserverTarget;
new Handle:hAttemptToExitFreezeCam;

public OnPluginStart()
{
	new Handle:conf = LoadGameConfigFile("all.games-observer");
	if(conf == INVALID_HANDLE)
	{
		SetFailState("why no gamedata ?");
	}

	new	offset = GameConfGetOffset(conf, "StartObserverMode()");
	if(offset != -1)
	{
		hStartObserverMode = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, StartObserverMode);
		DHookAddParam(hStartObserverMode, HookParamType_Int);
	}


	offset = GameConfGetOffset(conf, "StopObserverMode()");
	if(offset != -1)
	{
		hStopObserverMode = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, StopObserverMode);
	}


	offset = GameConfGetOffset(conf, "ModeWantsSpectatorGUI()");
	if(offset != -1)
	{
		hModeWantsSpectatorGUI = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, ModeWantsSpectatorGUI);
		DHookAddParam(hModeWantsSpectatorGUI, HookParamType_Int);
	}


	offset = GameConfGetOffset(conf, "SetObserverMode()");
	if(offset != -1)
	{
		hSetObserverMode = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, SetObserverMode);
		DHookAddParam(hSetObserverMode, HookParamType_Int);
	}


	offset = GameConfGetOffset(conf, "GetObserverMode()");
	if(offset != -1)
	{
		hGetObserverMode = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, GetObserverMode);
	}



	offset = GameConfGetOffset(conf, "SetObserverTarget()");
	if(offset != -1)
	{
		hSetObserverTarget = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, SetObserverTarget);
		DHookAddParam(hSetObserverTarget, HookParamType_CBaseEntity);
	}


	offset = GameConfGetOffset(conf, "ObserverUse()");
	if(offset != -1)
	{
		hObserverUse = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, ObserverUse);
		DHookAddParam(hObserverUse, HookParamType_Bool);
	}


	offset = GameConfGetOffset(conf, "GetObserverTarget()");
	if(offset != -1)
	{
		hGetObserverTarget = DHookCreate(offset, HookType_Entity, ReturnType_CBaseEntity, ThisPointer_CBaseEntity, GetObserverTarget);
	}


	offset = GameConfGetOffset(conf, "FindNextObserverTarget()");
	if(offset != -1)
	{
		hFindNextObserverTarget = DHookCreate(offset, HookType_Entity, ReturnType_CBaseEntity, ThisPointer_CBaseEntity, FindNextObserverTarget);
		DHookAddParam(hFindNextObserverTarget, HookParamType_Bool);
	}


	offset = GameConfGetOffset(conf, "GetNextObserverSearchStartPoint()");
	if(offset != -1)
	{
		hGetNextObserverSearchStartPoint = DHookCreate(offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, GetNextObserverSearchStartPoint);
		DHookAddParam(hGetNextObserverSearchStartPoint, HookParamType_Bool);
	}


	offset = GameConfGetOffset(conf, "IsValidObserverTarget()");
	if(offset != -1)
	{
		hIsValidObserverTarget = DHookCreate(offset, HookType_Entity, ReturnType_Bool, ThisPointer_CBaseEntity, IsValidObserverTarget);
		DHookAddParam(hIsValidObserverTarget, HookParamType_CBaseEntity);
	}


	offset = GameConfGetOffset(conf, "CheckObserverSettings()");
	if(offset != -1)
	{
		hCheckObserverSettings = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, CheckObserverSettings);
	}


	offset = GameConfGetOffset(conf, "JumptoPosition()");
	if(offset != -1)
	{
		hJumptoPosition = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, JumptoPosition);
		DHookAddParam(hJumptoPosition, HookParamType_VectorPtr);
		DHookAddParam(hJumptoPosition, HookParamType_VectorPtr);
	}


	offset = GameConfGetOffset(conf, "ForceObserverMode()");
	if(offset != -1)
	{
		hForceObserverMode = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, ForceObserverMode);
		DHookAddParam(hForceObserverMode, HookParamType_Int);
	}


	offset = GameConfGetOffset(conf, "ResetObserverMode()");
	if(offset != -1)
	{
		hResetObserverMode = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, ResetObserverMode);
	}

	offset = GameConfGetOffset(conf, "ValidateCurrentObserverTarget()");
	if(offset != -1)
	{
		hValidateCurrentObserverTarget = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, ValidateCurrentObserverTarget);
	}

	offset = GameConfGetOffset(conf, "AttemptToExitFreezeCam()");
	if(offset != -1)
	{
		hAttemptToExitFreezeCam = DHookCreate(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, AttemptToExitFreezeCam);
	}
	CloseHandle(conf);

	for(new i = 1; i <= MaxClients; i++) // Late plugin load
	{
		if(IsClientInGame(i))
		{
			OnClientPutInServer(i); // Hook again
		}
	}

}

	/*	Hooks	*/
public OnClientPutInServer(client)
{
	if(IsFakeClient(client))
		return;

		/* Remove double back slash to start hook player */

	hStartObserverMode					!= INVALID_HANDLE ? DHookEntity(hStartObserverMode,					false,		client) : 0;
	hStopObserverMode					!= INVALID_HANDLE ? DHookEntity(hStopObserverMode,					false,		client) : 0;
	hModeWantsSpectatorGUI				!= INVALID_HANDLE ? DHookEntity(hModeWantsSpectatorGUI,				false,		client) : 0;
	hSetObserverMode					!= INVALID_HANDLE ? DHookEntity(hSetObserverMode,					false,		client) : 0;
	//hGetObserverMode					!= INVALID_HANDLE ? DHookEntity(hGetObserverMode,					true,		client) : 0; //spam
	hSetObserverTarget					!= INVALID_HANDLE ? DHookEntity(hSetObserverTarget,					false,		client) : 0;
	hObserverUse						!= INVALID_HANDLE ? DHookEntity(hObserverUse,						false,		client) : 0;
	//hGetObserverTarget					!= INVALID_HANDLE ? DHookEntity(hGetObserverTarget,					true,		client) : 0; //spam
	hFindNextObserverTarget				!= INVALID_HANDLE ? DHookEntity(hFindNextObserverTarget,			true,		client) : 0;
	hGetNextObserverSearchStartPoint	!= INVALID_HANDLE ? DHookEntity(hGetNextObserverSearchStartPoint,	true,		client) : 0;
	//hIsValidObserverTarget				!= INVALID_HANDLE ? DHookEntity(hIsValidObserverTarget,				true,		client) : 0; //spam
	//hCheckObserverSettings				!= INVALID_HANDLE ? DHookEntity(hCheckObserverSettings,				false,		client) : 0; //spam
	hJumptoPosition						!= INVALID_HANDLE ? DHookEntity(hJumptoPosition,					false,		client) : 0;
	hForceObserverMode					!= INVALID_HANDLE ? DHookEntity(hForceObserverMode,					false,		client) : 0;
	hResetObserverMode					!= INVALID_HANDLE ? DHookEntity(hResetObserverMode,					false,		client) : 0;
	//hValidateCurrentObserverTarget		!= INVALID_HANDLE ? DHookEntity(hValidateCurrentObserverTarget,		false,		client) : 0; //spam
	hAttemptToExitFreezeCam				!= INVALID_HANDLE ? DHookEntity(hAttemptToExitFreezeCam,			false,		client) : 0;
}


	/* BELOW callbacks */

public MRESReturn:StartObserverMode(this, Handle:hReturn, Handle:hParams)
{
	PrintToServer("%i StartObserverMode successful:%s mode %i", this, DHookGetReturn(hReturn) ? "true":"false", DHookGetParam(hParams, 1));
	return MRES_Ignored;
}

public MRESReturn:StopObserverMode(this)
{
	PrintToServer("%i StopObserverMode", this);
	return MRES_Ignored;
}

public MRESReturn:ModeWantsSpectatorGUI(this, Handle:hReturn, Handle:hParams)
{
	PrintToServer("%i ModeWantsSpectatorGUI %s %i", this, DHookGetReturn(hReturn) ? "true":"false", DHookGetParam(hParams, 1));
	return MRES_Ignored;
}

public MRESReturn:SetObserverMode(this, Handle:hReturn, Handle:hParams)
{
	PrintToServer("%i SetObserverMode successful:%s mode %i", this, DHookGetReturn(hReturn) ? "true":"false", DHookGetParam(hParams, 1));
	return MRES_Ignored;
}

public MRESReturn:GetObserverMode(this, Handle:hReturn)
{
	// spam
	PrintToServer("%i GetObserverMode mode %i", this, DHookGetReturn(hReturn));
	return MRES_Ignored;
}

public MRESReturn:SetObserverTarget(this, Handle:hReturn, Handle:hParams)
{
	PrintToServer("%i SetObserverTarget bool:%s target %i", this, DHookGetReturn(hReturn) ? "true":"false", DHookGetParam(hParams, 1));
	return MRES_Ignored;
}

public MRESReturn:ObserverUse(this, Handle:hParams)
{
	PrintToServer("%i ObserverUse bIsPressed:%s", this, DHookGetParam(hParams, 1) ? "true":"false");
	return MRES_Ignored;
}

public MRESReturn:GetObserverTarget(this, Handle:hReturn)
{
	// spam
	PrintToServer("%i GetObserverTarget target:%i", this, DHookGetReturn(hReturn));
	return MRES_Ignored;
}

public MRESReturn:FindNextObserverTarget(this, Handle:hReturn, Handle:hParams)
{
	PrintToServer("%i FindNextObserverTarget target:%i bReverse %s", this, DHookGetReturn(hReturn), DHookGetParam(hParams, 1) ? "true":"false");
	return MRES_Ignored;
}

public MRESReturn:GetNextObserverSearchStartPoint(this, Handle:hReturn, Handle:hParams)
{
	PrintToServer("%i GetNextObserverSearchStartPoint point:%i bReverse %s", this, DHookGetReturn(hReturn), DHookGetParam(hParams, 1) ? "true":"false");
	return MRES_Ignored;
}

public MRESReturn:IsValidObserverTarget(this, Handle:hReturn, Handle:hParams)
{
	// spam
	PrintToServer("%i IsValidObserverTarget target:%i allow %s", this, DHookGetParam(hParams, 1), DHookGetReturn(hReturn) ? "true":"false");
	return MRES_Ignored;
}

public MRESReturn:CheckObserverSettings(this)
{
	// spam
	PrintToServer("%i CheckObserverSettings", this);
	return MRES_Ignored;
}


public MRESReturn:JumptoPosition(this, Handle:hParams)
{
	new Float:vec[3], Float:ang[3];
	DHookGetParamVector(hParams, 1, vec);
	DHookGetParamVector(hParams, 2, ang);
	PrintToServer("%i JumptoPosition vec %f %f %f, ang %f %f %f", this, vec[0], vec[1], vec[2], ang[0], ang[1], ang[2]);
	return MRES_Ignored;
}

public MRESReturn:ForceObserverMode(this, Handle:hParams)
{
	PrintToServer("%i ForceObserverMode mode %i", this, DHookGetParam(hParams, 1));
	return MRES_Ignored;
}

public MRESReturn:ResetObserverMode(this)
{
	PrintToServer("%i ResetObserverMode", this);
	return MRES_Ignored;
}

public MRESReturn:ValidateCurrentObserverTarget(this)
{
	//spam
	PrintToServer("%i ValidateCurrentObserverTarget", this);
	return MRES_Ignored;
}

public MRESReturn:AttemptToExitFreezeCam(this)
{
	PrintToServer("%i AttemptToExitFreezeCam", this);
	return MRES_Ignored;
}

