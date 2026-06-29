214c214
< 	g_hMinPlayersVersus = CreateConVar(		"sm_votekick_minplayers_versus","4",			"Minimum players present in versus games to allow starting vote for kick", CVAR_FLAGS );
---
> 	g_hMinPlayersVersus = CreateConVar(		"sm_votekick_minplayers_versus","4",			"Minimum players present in team to allow starting vote for kick (Versus gamemode)", CVAR_FLAGS );
519c519
< 																			// (had 3 pages of expired entries after 2 days, which were displayed on each !vk to the client)
---
> 																// (had 3 pages of expired entries after 2 days, which were displayed on each !vk to the client)
676,677d675
< 	if( target <= 0 )
< 		return false;
681,682c679,682
< 	if( target == 0 || !IsClientInGame(target) )
< 		return false;
---
> 	if( target != -1)
> 	{
> 		if( target == 0 || !IsClientInGame(target) )
> 			return false;
684,685c684,686
< 	if( client == target && bHasVoteAccessFlagClient )
< 		return true;
---
> 		// This comparison does not trigger an "Exception reported: Client index -1 is invalid", but logically precedes the subsequent comparison 
> 		if( client == target && bHasVoteAccessFlagClient )
> 			return true;
687,688c688,690
< 	if( IsClientRootAdmin(target) )
< 		return false;
---
> 		if( IsClientRootAdmin(target) )
> 			return false;
> 	}
720,723c722
< 	if( HasVoteAccessFlag(target) && !bHasVoteAccessFlagClient )
< 		return false;
< 
< 	if( GetImmunityLevel(client) < GetImmunityLevel(target) )
---
> 	if( target != -1)
725,728c724,725
< 		CPrintToChat(client, "%t", "no_access_immunity");
< 		LogVoteAction(client, "[DENY] Reason: Target immunity (%i) is higher than vote issuer (%i)", GetImmunityLevel(target), GetImmunityLevel(client));
< 		return false;
< 	}
---
> 		if( HasVoteAccessFlag(target) && !bHasVoteAccessFlagClient )
> 			return false;
730,731d726
< 	if( IsAdmin(target) && !IsAdmin(client) )
< 		return false;
733,740c728,733
< 	if( InDenyFile(target, g_hArrayVoteBlock) )	// allow to vote everybody against clients who located in deny list (regardless of vote access flag)
< 	{
< 		LogVoteAction(client, "[ALLOW] Reason: target is in deny list.");
< 		return true;
< 	}
< 	
< 	if( !g_bCvarShowBots && IsFakeClient(target) )
< 		return false;
---
> 		if( GetImmunityLevel(client) < GetImmunityLevel(target) )
> 		{
> 			CPrintToChat(client, "%t", "no_access_immunity");
> 			LogVoteAction(client, "[DENY] Reason: Target immunity (%i) is higher than vote issuer (%i)", GetImmunityLevel(target), GetImmunityLevel(client));
> 			return false;
> 		}
741a735,747
> 		if( IsAdmin(target) && !IsAdmin(client) )
> 			return false;
> 
> 		if( InDenyFile(target, g_hArrayVoteBlock) )	// allow to vote everybody against clients who located in deny list (regardless of vote access flag)
> 		{
> 			LogVoteAction(client, "[ALLOW] Reason: target is in deny list.");
> 			return true;
> 		}
> 
> 		if( !g_bCvarShowBots && IsFakeClient(target) )
> 			return false;
> 	}
> 		
1102c1108
< 				KickClient(client, "Kicked for violation");
---
> 				KickClient(client, "You have been kicked from session");
1123a1130
> 	if (g_iCvarAccessFlag == 0) return true;			// sm_votekick_accessflag="" (leave empty to allow for everybody)
