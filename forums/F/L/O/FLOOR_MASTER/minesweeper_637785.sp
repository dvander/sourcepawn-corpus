/** 
 * vim: set filetype=c :
 *
 * =============================================================================
 * Minesweeper
 *
 * Copyright 2008 Ryan Mannion. All Rights Reserved.
 * =============================================================================
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include <sourcemod>

#pragma semicolon 1
#define MS_COLS 9
#define MS_ROWS 9
#define MINE 'B'
#define EMPTY '_'
#define UNEARTHED 'X'
#define MAX_CLIENTS 32

#define MS_VERSION "0.1"

public Plugin:myinfo = {
    name = "Mineweeper",
    author = "Ryan \"FLOOR_MASTER\" Mannion",
    description = "9x9 Minesweeper",
    version = MS_VERSION,
    url = "http://www.2fort2furious.com"
};

#define CVAR_VERSION	    0
#define CVAR_MINES	    1
#define CVAR_NUM_CVARS	    2

enum MSState {
    MSState_Off = 0,
    MSState_Row,
    MSState_Col,
    MSState_End,
    MSState_Suspend
};

new Handle:g_cvars[CVAR_NUM_CVARS];
new MSState:MS_State[MAX_CLIENTS + 1];
new String:MS_Solution[MAX_CLIENTS + 1][MS_ROWS][MS_COLS + 1];
new String:MS_Display[MAX_CLIENTS + 1][MS_ROWS][MS_COLS + 1];
new MS_Row[MAX_CLIENTS + 1];
new MS_Cleared[MAX_CLIENTS + 1];
new MS_Time[MAX_CLIENTS + 1];
new MS_Score[MAX_CLIENTS + 1];
new MS_Mines[MAX_CLIENTS + 1];

public OnPluginStart() {

    g_cvars[CVAR_VERSION] = CreateConVar(
	"sm_minesweeper_version",
	MS_VERSION,
	"Minesweeper Version",
	FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvars[CVAR_MINES] = CreateConVar(
	"sm_minesweeper_mines",
	"6",
	"Default number of mines in field",
	FCVAR_PLUGIN,
	true, 1.0, true, 10.0);

    RegConsoleCmd("sm_ms", Command_Minesweeper);
}

stock IncrementMineCount(client, row, col) {
    if (row >= 0 && col >= 0 && row < MS_ROWS && col < MS_COLS && MS_Solution[client][row][col] != MINE) {
	if (MS_Solution[client][row][col] == EMPTY) {
	    MS_Solution[client][row][col] = '1';
	}
	else {
	    MS_Solution[client][row][col]++;
	}
    }
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen) {
    MS_State[client] = MSState_Off;
    return true;
}

public OnClientDisconnect(client) {
    MS_State[client] = MSState_Off;
}

stock NewGame(client, mines) {
    new i, j;
    MS_State[client] = MSState_Row;
    MS_Time[client] = GetTime();
    MS_Score[client] = 1000;

    for (i = 0; i < MS_ROWS; i++) {
	for (j = 0; j < MS_COLS; j++) {
	    MS_Solution[client][i][j] = EMPTY;
	    MS_Display[client][i][j] = UNEARTHED; 
	}
	MS_Solution[client][i][MS_COLS] = 0;
	MS_Display[client][i][MS_COLS] = 0;
    }

    MS_Mines[client] = mines;
    PrintToChat(client, "%cStarting new Minesweeper game with %d mine%s", 4, mines, (mines == 1 ? "" : "s"));

    new row, col;
    for (i = 0; i < mines; i++) {
	do {
	    row = GetRandomInt(0, MS_ROWS - 1);
	    col = GetRandomInt(0, MS_COLS - 1);

	} while (MS_Solution[client][row][col] == MINE);

	MS_Solution[client][row][col] = MINE;

	IncrementMineCount(client, row - 1, col - 1);
	IncrementMineCount(client, row - 1, col);
	IncrementMineCount(client, row - 1, col + 1);
	IncrementMineCount(client, row, col - 1);
	IncrementMineCount(client, row, col + 1);
	IncrementMineCount(client, row + 1, col - 1);
	IncrementMineCount(client, row + 1, col);
	IncrementMineCount(client, row + 1, col + 1);
    }
    MS_Cleared[client] = MS_ROWS * MS_COLS;
}

stock DrawGame(client, MSState:myState, data=0) {
    switch (myState) {
	case MSState_Row: {
	    new Handle:panel = CreatePanel();
    	    SetPanelTitle(panel, "Minesweeper\nSelect a row:");
    	    DrawPanelText(panel, "    123456789");
    	    for (new i = 0; i < MS_ROWS; i++) {
		DrawPanelItem(panel, MS_Display[client][i]);
	    }
	    DrawPanelItem(panel, "Exit and Save");
	    SendPanelToClient(panel, client, Menu_Minesweeper, 0);
	    CloseHandle(panel);
	}
	case MSState_Col: {
	    decl String:title[128];
	    new Handle:panel = CreatePanel();
	    Format(title, sizeof(title), "Minesweeper\nRow %d. Select a column:", data);
    	    SetPanelTitle(panel, title);
    	    DrawPanelText(panel, "    123456789");
    	    for (new i = 0; i < MS_ROWS; i++) {
		DrawPanelItem(panel, MS_Display[client][i]);
	    }
	    DrawPanelItem(panel, "Cancel Row");
	    SendPanelToClient(panel, client, Menu_Minesweeper, 0);
	    CloseHandle(panel);
	}
	case MSState_End: {
	    decl String:title[128];
	    MS_Score[client] -= GetTime() - MS_Time[client];
	    new Handle:panel = CreatePanel();
		
	    if (MS_Cleared[client] == MS_Mines[client]) {
		new score = (MS_Score[client] > 0 ? MS_Score[client] : 0);
		Format(title, sizeof(title), "Minesweeper\nYou win! Your score: %d", score);
		LogAction(client, -1, "%L won a game of minesweeper. Difficulty: %d. Score: %d.", client, MS_Mines[client], score);
		if (MS_Mines[client] > 5) {
		    PrintToChatAll("%c%N won a game of minesweeper (%d mines)!", 4, client, MS_Mines[client]);
		}
	    }
	    else {
		Format(title, sizeof(title), "Minesweeper\nYou lose!");
	    }

    	    SetPanelTitle(panel, title);
    	    DrawPanelText(panel, "    123456789");
    	    for (new i = 0; i < MS_ROWS; i++) {
		DrawPanelItem(panel, MS_Solution[client][i], ITEMDRAW_DISABLED);
	    }
	    DrawPanelItem(panel, "Exit");
	    SendPanelToClient(panel, client, Menu_Minesweeper, 0);
	    CloseHandle(panel);

	    MS_State[client] = MSState_Off;
	}
    }
}

stock ClearAbutting(client, row, col) {
    new rown = row - 1;
    new coln = col - 1;

    if (rown >= 0 && coln >= 0 && MS_Display[client][rown][coln] != MS_Solution[client][rown][coln]) {
	MS_Display[client][rown][coln] = MS_Solution[client][rown][coln];
	MS_Cleared[client]--;
	if (MS_Display[client][rown][coln] == EMPTY) {
	    ClearAbutting(client, rown, coln);
	}
    }

    coln = col;
    if (rown >= 0 && MS_Display[client][rown][coln] != MS_Solution[client][rown][coln]) {
	MS_Display[client][rown][coln] = MS_Solution[client][rown][coln];
	MS_Cleared[client]--;
	if (MS_Display[client][rown][coln] == EMPTY) {
	    ClearAbutting(client, rown, coln);
	}
    }

    coln = col + 1;
    if (rown >= 0 && coln < MS_COLS && MS_Display[client][rown][coln] != MS_Solution[client][rown][coln]) {
	MS_Display[client][rown][coln] = MS_Solution[client][rown][coln];
	MS_Cleared[client]--;
	if (MS_Display[client][rown][coln] == EMPTY) {
	    ClearAbutting(client, rown, coln);
	}
    }

    rown = row;
    coln = col - 1;
    if (coln >= 0 && MS_Display[client][rown][coln] != MS_Solution[client][rown][coln]) {
	MS_Display[client][rown][coln] = MS_Solution[client][rown][coln];
	MS_Cleared[client]--;
	if (MS_Display[client][rown][coln] == EMPTY) {
	    ClearAbutting(client, rown, coln);
	}
    }

    rown = row;
    coln = col + 1;
    if (coln < MS_COLS && MS_Display[client][rown][coln] != MS_Solution[client][rown][coln]) {
	MS_Display[client][rown][coln] = MS_Solution[client][rown][coln];
	MS_Cleared[client]--;
	if (MS_Display[client][rown][coln] == EMPTY) {
	    ClearAbutting(client, rown, coln);
	}
    }

    rown = row + 1;
    coln = col - 1;
    if (rown < MS_ROWS && coln >= 0 && MS_Display[client][rown][coln] != MS_Solution[client][rown][coln]) {
	MS_Display[client][rown][coln] = MS_Solution[client][rown][coln];
	MS_Cleared[client]--;
	if (MS_Display[client][rown][coln] == EMPTY) {
	    ClearAbutting(client, rown, coln);
	}
    }

    coln = col;
    if (rown < MS_ROWS && MS_Display[client][rown][coln] != MS_Solution[client][rown][coln]) {
	MS_Display[client][rown][coln] = MS_Solution[client][rown][coln];
	MS_Cleared[client]--;
	if (MS_Display[client][rown][coln] == EMPTY) {
	    ClearAbutting(client, rown, coln);
	}
    }

    coln = col + 1;
    if (rown < MS_ROWS && coln < MS_COLS && MS_Display[client][rown][coln] != MS_Solution[client][rown][coln]) {
	MS_Display[client][rown][coln] = MS_Solution[client][rown][coln];
	MS_Cleared[client]--;
	if (MS_Display[client][rown][coln] == EMPTY) {
	    ClearAbutting(client, rown, coln);
	}
    }
}

public Menu_Minesweeper(Handle:menu, MenuAction:action, param1, param2) {
    new client = param1;

    switch (action) {
	case MenuAction_Select: {
	    switch (MS_State[client]) {
		case MSState_Suspend: {
		    switch (param2) {
			case 1: {
			    MS_Time[client] = GetTime();
			    MS_State[client] = MSState_Row;
			    DrawGame(client, MSState_Row, param2);
			}
			case 2: {
			    NewGame(client, MS_Mines[client]);
			    DrawGame(client, MS_State[client]);
			}
			case 3: {
			    MS_State[client] = MSState_Suspend;
			}
		    }
		}
		case MSState_Row: {
		    MS_Row[client] = param2;
		    if (param2 < 10) {
			MS_State[client] = MSState_Col;
			DrawGame(client, MSState_Col, param2);
		    }
		    else {
			MS_State[client] = MSState_Suspend;
			MS_Score[client] -= GetTime() - MS_Time[client];
			MS_Time[client] = GetTime();
		    }
		}
		case MSState_Col: {
		    if (param2 == 10) {
			MS_State[client] = MSState_Row;
			DrawGame(client, MSState_Row, param2);
		    }
		    else {
			new row = MS_Row[client] - 1;
			new col = param2 - 1;
			new el = MS_Solution[client][row][col];

			if (el == MINE) {
			    MS_State[client] = MSState_End;
			    DrawGame(client, MSState_End, param2);
			}
			else {
			    if (MS_Display[client][row][col] != el) {
				MS_Cleared[client]--;
				MS_Display[client][row][col] = el;
				if (el == EMPTY) {
				    ClearAbutting(client, row, col);
				}
			    }
			    if (MS_Cleared[client] == MS_Mines[client]) {
				MS_State[client] = MSState_End;
				DrawGame(client, MSState_End, param2);
			    }
			    else {
				MS_State[client] = MSState_Row;
			    	DrawGame(client, MSState_Row);
			    }
			}
		    }
		}
		case MSState_End: {
		    MS_State[client] = MSState_Suspend;
		    MS_Score[client] -= GetTime() - MS_Time[client];
		    PrintToChat(client, "Thanks for playing!");
		}
	    }
	}
	case MenuAction_Cancel: {
	}
	case MenuAction_End: {
	}
    }
}

public Action:Command_Minesweeper(client, args) {
    new mines = GetConVarInt(g_cvars[CVAR_MINES]);
    if (args) {
	decl String:arg[32];
	GetCmdArg(1, arg, sizeof(arg));
	mines = StringToInt(arg);
	if (mines < 1) {
	    mines = 1;
	}
	else if (mines > 10) {
	    mines = 10;
	}

	NewGame(client, mines);
	DrawGame(client, MS_State[client]);
	return Plugin_Handled;
    }

    switch (MS_State[client]) {
	case MSState_Off: {
	    NewGame(client, mines);
	    DrawGame(client, MS_State[client]);
	}
	default: {
	    if (MS_State[client] != MSState_Suspend) {
		MS_Score[client] -= GetTime() - MS_Time[client];
		MS_Time[client] = GetTime();
	    }
	    MS_State[client] = MSState_Suspend;

	    new Handle:panel = CreatePanel();
    	    SetPanelTitle(panel, "Minesweeper\nYou have a game in progress:");
	    DrawPanelItem(panel, "Resume Game");
	    DrawPanelItem(panel, "Start New Game");
	    DrawPanelItem(panel, "Exit");
	    SendPanelToClient(panel, client, Menu_Minesweeper, 0);
	    CloseHandle(panel);
	}
    }
    return Plugin_Handled;
}

