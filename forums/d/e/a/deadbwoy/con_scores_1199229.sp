/**
* Counter-Strike: Source Console Scoreboard
* http://www.brotherhoodofgamers.com/
* Copyright (C) 2010 Deadbwoy
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public License
* as published by the Free Software Foundation; either version 2
* of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.
* 
* You should have received a copy of the GNU General Public License
* along with this program; if not, write to the Free Software
* Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*
*
* TO DO:
*	Add stuff!
*
*/
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

public Plugin:myinfo={
	name = "Console Scoreboard",
	author = "Deadbwoy",
	description = "Shows scoreboard in console",
	version = "0.3",
	url = "http://www.brotherhoodofgamers.com/"
};

new Handle:SCORED = INVALID_HANDLE, Handle:SPEC = INVALID_HANDLE;

public OnPluginStart(){
	RegServerCmd("scores", css_scores, "Display scoreboard in console");
	SCORED = CreateArray(64, 0);
	SPEC = CreateArray(64, 0);
}

public OnMapStart()
	ClearArray(SCORED), ClearArray(SPEC);

public Action:css_scores(args){

	// Clear Scoreboard Data
	ClearArray(SCORED), ClearArray(SPEC);

	// Start Print of new Scoreboard
	// Print Scoreboard header
	PrintToServer("=========================================================================");
	PrintToServer("|        TERRORISTS:        | K | D |    COUNTER TERRORISTS:    | K | D |");
	PrintToServer("=========================================================================");

	// Create variables
	new String:TName[28], String:CTName[28], TTOP = 0, TTOPS = 0, TTOPD = 0, CTTOP = 0, CTTOPS = 0, CTTOPD = 0, YYY = 0, SPECTATOR = 0;

	// Start Scoreboard Computations
	// Loop 1 for printing scoreboard data
	for(new k = 1; k <= (MaxClients / 2); k++){

		// Loop 2 for Finding top player userId of each team (TTOP & CTTOP)
		for(new i = 1; i <= MaxClients; i++){
			if(IsClientInGame(i) && IsClientConnected(i)){

				// Create Client variables
				new TEAMINT = GetClientTeam(i), KILLS = 0, DEATHS = 0, UID = 0, ZZZ = 0;
				KILLS = GetClientFrags(i), DEATHS = GetClientDeaths(i), UID = GetClientUserId(i);

				// Loop 3 to find and skip players already printed to scoreboard
				for(new j = 0; j < GetArraySize(SCORED); j++){
					new CHECK = GetArrayCell(SCORED, j);
					if(CHECK == UID){
						ZZZ = 1;
						break;
					}
				}

				// If player score has been printed
				if(ZZZ == 1)
					continue;

				// Terrorist team check for top player
				// If UserId of client is not stored as the high scorer
				if(TEAMINT == 2 && UID != TTOP){

					// If Kills > High Scorer
					// Store data in high scorer placeholders (TTOP-UserID, TTOPS-Kills, TTOPD, Deaths)
					if(KILLS > TTOPS){
						TTOPS = KILLS, TTOP = UID, TTOPD = DEATHS;
						continue;

					// If client's Kills = high scorer's kills
					}else if(KILLS == TTOPS){

						// If client has less deaths
						if(DEATHS < TTOPD){
							TTOPS = KILLS, TTOP = UID, TTOPD = DEATHS;
							continue;

						// If Cient has equal deaths
						}else if(DEATHS == TTOPD){
							TTOPS = KILLS, TTOP = UID, TTOPD = DEATHS;
							continue;
						}
					}
				}

				// Special step to handle KILLS = 0 or < 0
				if(TEAMINT == 2 && UID != TTOP && TTOP == 0){
					if(KILLS == 0 && DEATHS == 0){
						TTOPS = KILLS, TTOP = UID, TTOPD = DEATHS;
						continue;

					// If client's Kills = high scorer's kills
					}else if(KILLS == 0 && DEATHS > 0){
						TTOPS = KILLS, TTOP = UID, TTOPD = DEATHS;
						continue;
					}else if(KILLS < 0 && DEATHS == 0){
						TTOPS = KILLS, TTOP = UID, TTOPD = DEATHS;
						continue;
					}else if(KILLS < 0 && DEATHS > 0){
						TTOPS = KILLS, TTOP = UID, TTOPD = DEATHS;
						continue;
					}
				}


				// Counter Terrorist team check for top player
				// If UserId of client is not stored as the high scorer
				if(TEAMINT == 3 && UID != CTTOP){

					// If Kills > High Scorer
					// Store data in high scorer placeholders (CTTOP-UserID, CTTOPS-Kills, CTTOPD, Deaths)
					if(KILLS > CTTOPS){
						CTTOPS = KILLS, CTTOP = UID, CTTOPD = DEATHS;
						continue;
					}else if(KILLS == CTTOPS){

						// If client has less deaths
						if(DEATHS < CTTOPD){
							CTTOPS = KILLS, CTTOP = UID, CTTOPD = DEATHS;
							continue;

						// If Cient has equal deaths
						}else if(DEATHS == CTTOPD){
							CTTOPS = KILLS, CTTOP = UID, CTTOPD = DEATHS;
							continue;
						}
					}
				}

				// Special step to handle KILLS = 0 or < 0
				if(TEAMINT == 3 && UID != CTTOP && CTTOP == 0){
					if(KILLS == 0 && DEATHS == 0){
						CTTOPS = KILLS, CTTOP = UID, CTTOPD = DEATHS;
						continue;

					// If client's Kills = high scorer's kills
					}else if(KILLS == 0 && DEATHS > 0){
						CTTOPS = KILLS, CTTOP = UID, CTTOPD = DEATHS;
						continue;
					}else if(KILLS < 0 && DEATHS == 0){
						CTTOPS = KILLS, CTTOP = UID, CTTOPD = DEATHS;
						continue;
					}else if(KILLS < 0 && DEATHS > 0){
						CTTOPS = KILLS, CTTOP = UID, CTTOPD = DEATHS;
						continue;
					}
				}

				// Populate Spectator list
				if(TEAMINT == 1 && YYY == 0 && SPECTATOR != UID){
					SPECTATOR = UID;
					PushArrayCell(SPEC, UID);
					continue;
				}
			}
		}

		// This is a switch to tell loop 1 that spectators have been handled, leave them alone
		YYY = 1;

		// Start Printing of clients on scoreboard
		// If both teams have a client stored as high scorer
		if(TTOP > 0 && CTTOP > 0){

			// Get Client names
			GetClientName(GetClientOfUserId(TTOP), TName, 28);
			GetClientName(GetClientOfUserId(CTTOP), CTName, 28);

			// Edit names with utf characters to preserve scoreboard layout
			new NumTBytes = 0, NumCTBytes = 0, TB = 0, CTB = 0, TXB = 0, CTXB = 0;
			for(new m = 0; m <= strlen(TName); m++){
				if(IsCharMB(TName[m] > 0)){
					NumTBytes += GetCharBytes(TName[m]);
					TB = 1, TXB++;
					continue;
				}
				NumTBytes++;
			}
			for(new n = 0; n <= strlen(CTName); n++){
				if(IsCharMB(CTName[n])){
					NumCTBytes += GetCharBytes(CTName[n]);
					CTB = 1, CTXB++;
					continue;
				}
				NumCTBytes++;
			}

			// Create new string variables to make sure everything is lined up properly
			new String:A[28], String:B[28], String:AK[4], String:BK[4], String:AD[4], String:BD[4];

			// Format the names to be a block of 28 characters
			// Hense the spaces after %s
			//
			// Display # of bytes in each name
			// and format strings accordingly
			if(TB == 1){
				//LogToGame("====== UTF8 found in TName! detected length = \"%i\", real length = \"%i\" ======", NumTBytes, (NumTBytes + TXB));
				Format(A, (28 + TXB), "%s                            ", TName);
			}
			if(CTB == 1){
				//LogToGame("====== UTF8 found in CTName! detected length = \"%i\", real length = \"%i\" ======", NumCTBytes, (NumCTBytes + CTXB));
				Format(B, (28 + CTXB), "%s                            ", TName);
			}
			if(TB == 0)
				Format(A, 28, "%s                            ", TName);
			if(CTB == 0)
				Format(B, 28, "%s                            ", CTName);

			// Format the numbers to be a block of 4 characters
			// to prevent scoreboard fields from resizing
			// according to the size of the number
			IntToString(TTOPS, AK, 4), IntToString(TTOPD, AD, 4), IntToString(CTTOPS, BK, 4), IntToString(CTTOPD, BD, 4);
			Format(AK, 4, "%s    ", AK);
			Format(AD, 4, "%s    ", AD);
			Format(BK, 4, "%s    ", BK);
			Format(BD, 4, "%s    ",	BD);

			// Print line onto scoreboard
			PrintToServer("|%s|%s|%s|%s|%s|%s|", A, AK, AD, B, BK, BD);

			// Store UserId's in SCORED array
			PushArrayCell(SCORED, TTOP);
			PushArrayCell(SCORED, CTTOP);

			// Set variables back to zero for the re-loop
			// to find the next highest scored players
			TTOPS = 0, TTOP = 0, TTOPD = 0, CTTOPS = 0, CTTOP = 0, CTTOPD = 0, NumTBytes = 0, NumCTBytes = 0, TB = 0, CTB = 0, TXB = 0, CTXB = 0;

		// If only CT's have a high scorer
		}else if(TTOP == 0 && CTTOP > 0){
			GetClientName(GetClientOfUserId(CTTOP), CTName, 28);

			// Edit names with utf characters to preserve scoreboard layout
			new NumCTBytes = 0, CTB = 0, CTXB = 0;
			for(new n = 0; n <= strlen(CTName); n++){
				if(IsCharMB(CTName[n])){
					NumCTBytes += GetCharBytes(CTName[n]);
					CTB = 1, CTXB++;
					continue;
				}
				NumCTBytes++;
			}

			// Create new string variables to make sure everything is lined up properly
			new String:A[28], String:B[28], String:AK[4], String:BK[4], String:AD[4], String:BD[4];

			// Format the names to be a block of 28 characters
			// Hense the spaces after %s
			//
			// Display # of bytes in each name
			// and format strings accordingly
			if(CTB == 1){
				//LogToGame("====== UTF8 found in CTName! detected length = \"%i\", real length = \"%i\" ======", NumCTBytes, (NumCTBytes + CTXB));
				Format(B, (28 + CTXB), "%s                            ", TName);
			}
			Format(A, 28, "%s                            ", TName);
			if(CTB == 0)
				Format(B, 28, "%s                            ", CTName);
			IntToString(TTOPS, AK, 4), IntToString(TTOPD, AD, 4), IntToString(CTTOPS, BK, 4), IntToString(CTTOPD, BD, 4);
			Format(AK, 4, "    ");
			Format(AD, 4, "    ");
			Format(BK, 4, "%s    ", BK);
			Format(BD, 4, "%s    ",	BD);
			PrintToServer("|%s|%s|%s|%s|%s|%s|", A, AK, AD, B, BK, BD);
			PushArrayCell(SCORED, CTTOP);
			CTTOPS = 0, CTTOP = 0, CTTOPD = 0, NumCTBytes = 0, CTB = 0, CTXB = 0;

		// If only T's have a high scorer
		}else if(TTOP > 0 && CTTOP == 0){
			GetClientName(GetClientOfUserId(TTOP), TName, 28);

			// Edit names with utf characters to preserve scoreboard layout
			new NumTBytes = 0, TB = 0, TXB = 0;
			for(new m = 0; m <= strlen(TName); m++){
				if(IsCharMB(TName[m] > 0)){
					NumTBytes += GetCharBytes(TName[m]);
					TB = 1, TXB++;
					continue;
				}
				NumTBytes++;
			}

			// Create new string variables to make sure everything is lined up properly
			new String:A[28], String:B[28], String:AK[4], String:BK[4], String:AD[4], String:BD[4];

			// Format the names to be a block of 28 characters
			// Hense the spaces after %s
			//
			// Display # of bytes in each name
			// and format strings accordingly
			if(TB == 1){
				//LogToGame("====== UTF8 found in TName! detected length = \"%i\", real length = \"%i\" ======", NumTBytes, (NumTBytes + TXB));
				Format(A, (28 + TXB), "%s                            ", TName);
			}
			if(TB == 0)
				Format(A, 28, "%s                            ", TName);
			Format(B, 28, "%s                            ", CTName);
			IntToString(TTOPS, AK, 4), IntToString(TTOPD, AD, 4), IntToString(CTTOPS, BK, 4), IntToString(CTTOPD, BD, 4);
			Format(AK, 4, "%s    ", AK);
			Format(AD, 4, "%s    ", AD);
			Format(BK, 4, "    ");
			Format(BD, 4, "    ");
			PrintToServer("|%s|%s|%s|%s|%s|%s|", A, AK, AD, B, BK, BD);
			PushArrayCell(SCORED, TTOP);
			TTOPS = 0, TTOP = 0, TTOPD = 0, NumTBytes = 0, TB = 0, TXB = 0;

		// End of players in game
		}else{

			// Print scoreboard footer
			PrintToServer("=========================================================================");

			// Check for spectators
			// if so, print spec scoreboard
			if(GetArraySize(SPEC) > 0){

				// Print Spec Scores header
				PrintToServer("|        SPECTATORS:        | K | D |");
				PrintToServer("=====================================");

				// Loop 4 for populating spectator scoreboard
				for(new l = 0; l < GetArraySize(SPEC); l++){

					// Create spec variables
					new SUID = GetArrayCell(SPEC, l), String:SName[28], String:SName2[28], String:SK[4], String:SD[4];
					new SIDX = GetClientOfUserId(SUID);
					GetClientName(SIDX, SName, 28);

					// Edit names with utf characters to preserve scoreboard layout
					new NumSBytes = 0, SB = 0, SXB = 0;
					for(new n = 0; n <= strlen(SName); n++){
						if(IsCharMB(SName[n] > 0)){
							NumSBytes += GetCharBytes(SName[n]);
							SB = 1, SXB++;
							continue;
						}
						NumSBytes++;
					}
					if(SB == 1)
						Format(SName2, (28 + SXB), "%s                            ", SName);
					if(SB == 0)
						Format(SName2, 28, "%s                            ", SName);

					// Format numbers for correct spacing
					IntToString(GetClientFrags(SIDX), SK, 4), IntToString(GetClientDeaths(SIDX), SD, 4);
					Format(SK, 4, "%s    ", SK);
					Format(SD, 4, "%s    ", SD);

					// Print spectator scoreboard line
					PrintToServer("|%s|%s|%s|", SName2, SK, SD);
				}

				// Done printing spectators
				// Print spec scores footer
				PrintToServer("=====================================");
			}

			// Set variables back to zero for next exec of scores
			// We're done, break the printer = Loop 1
			CTTOPS = 0, CTTOP = 0, CTTOPD = 0, TTOPS = 0, TTOP = 0, TTOPD = 0;
			break;
		}
	}

	// We're done, clear scoreboard info in arrays
	ClearArray(SCORED), ClearArray(SPEC), YYY = 0;
}