// 3: Unless you removed the option, if a player calls melee and defeats the other team until their last player it no longer asks the other player if he would like to turn melee mode off.

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <melee>
#include <nativevotes>

new bool:check = false;
new Handle:CvarEnabled;
#define INVALID_PLAYER_INDEX -1
#define PLUGIN_VERSION "0.2.3"

public Plugin:myinfo = {
    name = "Last Person Melee",
    author = "Yoda12999",
    description = "Asks the last player alive on a team whether they want to fight the other team with melee only. Now with voting for the last two alive if melee hsn't been called yet!",
    version = PLUGIN_VERSION,
    url = "http://forums.alliedmods.net/showthread.php?t=145847"
}

public OnPluginStart() {
    CreateConVar("last_melee_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
    CvarEnabled = CreateConVar("last_melee_enabled", "1", "0 - Last person melee is disabled | 1 - Last person melee is enabled");
    HookEvent("player_death", EventPlayer_Death);
    HookEvent("player_disconnect", EventPlayer_Disconnect, EventHookMode_Pre);
    HookEvent("teamplay_round_win", EventRound_Win, EventHookMode_PostNoCopy);
    HookEvent("arena_round_start", EventRound_Start, EventHookMode_PostNoCopy);
}

public EventRound_Start(Handle:event, const String:name[], bool:dontBroadcast) {
    if(GetConVarInt(CvarEnabled)) {
        SetMeleeMode(false, false);
        check = false;
    }
}

public EventRound_Win(Handle:event, const String:name[], bool:dontBroadcast) {
    if(GetConVarInt(CvarEnabled)) {
        SetMeleeMode(false, false);
        check = true;
    }
}

public Action:EventPlayer_Disconnect(Handle:event, const String:name[], bool:dontBroadcast) {
    if(GetConVarInt(CvarEnabled)) {
        new team = GetClientTeam(GetClientOfUserId(GetEventInt(event, "userid")));
        if(team >= 2) {
            CreateTimer(1.0, Death_Timer, team);
        } else {
            CreateTimer(1.0, Death_Timer, 4);
        }
    }
    return Plugin_Continue;
}

public Action:EventPlayer_Death(Handle:event, const String:name[], bool:dontBroadcast) {
    if(GetConVarInt(CvarEnabled)) {
        if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)) {
            CreateTimer(1.0, Death_Timer, GetClientTeam(GetClientOfUserId(GetEventInt(event, "userid"))));
        }
    }
    return Plugin_Continue;
}

public Action:Death_Timer(Handle:timer, any:team) {
    new l_team = team;
    if(l_team == 4) {
        if(GetPlayersAlive(2) == 1) {
            l_team = 2;
        } else if(GetPlayersAlive(3) == 1) {
            l_team = 3;
        } else {
            return;
        }
    }
    if(!check) {
        if((GetPlayersAlive(l_team) == 1) && (GetPlayersAlive(GetOtherTeam(l_team)) != 1)) {
            MenuMelee(GetLastPlayer(l_team));
        } else if((GetPlayersAlive(2) == 1) && (GetPlayersAlive(3) == 1)) {
            switch (l_team) {
                case 2: {
                    if (GetPlayersAlive(3) == 1) {
                        VoteMelee(GetLastPlayer(l_team), GetLastPlayer(3));
                    } 
                }
                case 3: {
                    if (GetPlayersAlive(2) == 1) {
                        VoteMelee(GetLastPlayer(2), GetLastPlayer(l_team));
                    } 
                }
            }
        }
    }
}

public Handle_VoteResults(Handle:menu, num_votes, num_clients, const client_indexes[], const client_votes[], num_items, const item_indexes[], const item_votes[]) {
    if(item_votes[NATIVEVOTES_VOTE_YES] == 2) {
        SetMeleeMode(true, false);
        NativeVotes_DisplayPassCustom(menu, "Melee has been called!");
        check = true;
    } else {
        NativeVotes_DisplayPassCustom(menu, "Melee has been declined!");
        check = true;
    }
}

public MenuHandler(Handle:menu, MenuAction:action, param1, param2) {
    if(action == MenuAction_Select) {
        new String:player[32];
        GetClientName(param1, player, sizeof(player));

        if(param2 == 0) {
            SetMeleeMode(true, false);
            NativeVotes_DisplayPassCustom(menu, "%s has called Melee!", player);
            check = true;
        } else {
            NativeVotes_DisplayPassCustom(menu, "%s has declined Melee!", player);
        }
    } else if(action == MenuAction_VoteCancel) {
        NativeVotes_DisplayFail(menu, NativeVotesFail_NotEnoughVotes);
    } else if(action == MenuAction_End) {
        NativeVotes_Close(menu);
    }
}

public VoteHandler(Handle:menu, MenuAction:action, param1, param2) {
    if(action == MenuAction_VoteCancel) {
        NativeVotes_DisplayFail(menu, NativeVotesFail_NotEnoughVotes);
    } else if(action == MenuAction_End) {
        NativeVotes_Close(menu);
    }
}

MenuMelee(client) {
    new clients[1];
    clients[0] = client;
    new Handle:menu = NativeVotes_Create(MenuHandler, NativeVotesType_Custom_YesNo, NATIVEVOTES_ACTIONS_DEFAULT|MenuAction_Select);
    NativeVotes_SetDetails(menu, "Would you like to call Melee?");
    NativeVotes_Display(menu, clients, 1, 7);
}

VoteMelee(client1, client2) {
    if(NativeVotes_IsVoteInProgress()) {
        return;
    }
    new clients[2];
    clients[0] = client1;
    clients[1] = client2;
    new Handle:menu = NativeVotes_Create(VoteHandler, NativeVotesType_Custom_YesNo);
    NativeVotes_SetResultCallback(menu, Handle_VoteResults);
    NativeVotes_SetDetails(menu, "Fight melee one on one?");
    NativeVotes_Display(menu, clients, 2, 20);
}

GetOtherTeam(const team) {
    switch(team) {
        case 2: {
            return 3;
        }
        case 3: {
            return 2;
        }
        default: {
            return -1;
        }
    }
    return -1;
}

GetLastPlayer(const team) {
    new playerIndex = INVALID_PLAYER_INDEX;
    for(new i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i) && IsPlayerAlive(i) && (GetClientTeam(i) == team)) {
            if(playerIndex == INVALID_PLAYER_INDEX) {
                playerIndex = i;
            } else {
                PrintToServer("Error: more than one alive player in the team %d", team);
                return INVALID_PLAYER_INDEX;
            }
        }
    }
    return playerIndex;
}

GetPlayersAlive(const team) {
    new players;
    for(new i = 1; i <= MaxClients; i++) {
        if(IsClientInGame(i)) {
            if((GetClientTeam(i) == team) && IsPlayerAlive(i)){
                players++;
            }
        }
    }
    return players;
}