#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = {
	name = "1337 Speak",
	author = "Matthias Vance",
	description = "Everybody can be 1337 now.",
	version = PLUGIN_VERSION,
	url = "http://www.matthiasvance.com/"
};

public OnPluginStart() {
	CreateConVar("leetspeak_version", PLUGIN_VERSION, "Everybody can be 1337 now.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	RegConsoleCmd("say", cmd_Say);
}

public Action:cmd_Say(client, argCount) {

	// Filter console
	// if(!client) return Plugin_Continue;

	// Construct 1337 message.
	decl String:message[256];
	GetCmdArgString(message, sizeof(message));
	new String:newMessage[512];
	new length = sizeof(newMessage);
	for(new i = 0; i < strlen(message); i++) {
		switch(message[i]) {
			case 'a', 'A': {
				if(GetRandomInt(0, 1)) {
					StrCat(newMessage, length, "@");
				} else {
					StrCat(newMessage, length, "4");
				}
			}
			case 'b', 'B': {
				if(GetRandomInt(0, 1)) {
					StrCat(newMessage, length, "|3");
				} else {
					StrCat(newMessage, length, "8");
				}
			}
			case 'c', 'C': {
				StrCat(newMessage, length, "<");
			}
			case 'd', 'D': {
				StrCat(newMessage, length, "|)");
			}
			case 'e', 'E': {
				StrCat(newMessage, length, "3");
			}
			case 'f', 'F': {
				StrCat(newMessage, length, "]=");
			}
			case 'g', 'G': {
				StrCat(newMessage, length, "6");
			}
			case 'h', 'H': {
				StrCat(newMessage, length, "|-|");
			}
			case 'i', 'I': {
				StrCat(newMessage, length, "1");
			}
			case 'j', 'J': {
				StrCat(newMessage, length, "_|");
			}
			case 'k', 'K': {
				if(GetRandomInt(0, 1)) {
					StrCat(newMessage, length, "|<");
				} else {
					StrCat(newMessage, length, "|{");
				}
			}
			case 'l', 'L': {
				StrCat(newMessage, length, "1");
			}
			case 'm', 'M': {
				StrCat(newMessage, length, "|\\/|");
			}
			case 'n', 'N': {
				StrCat(newMessage, length, "|\\|");
			}
			case 'o', 'O': {
				StrCat(newMessage, length, "0");
			}
			case 'p', 'P': {
				StrCat(newMessage, length, "|*");
			}
			case 'q', 'Q': {
				StrCat(newMessage, length, "<|");
			}
			case 'r', 'R': {
				StrCat(newMessage, length, "|2");
			}
			case 's', 'S': {
				StrCat(newMessage, length, "5");
			}
			case 't', 'T': {
				StrCat(newMessage, length, "7");
			}
			case 'u', 'U': {
				StrCat(newMessage, length, "|_|");
			}
			case 'x', 'X': {
				if(GetRandomInt(0, 2)) {
					StrCat(newMessage, length, "><");
				} else {
					StrCat(newMessage, length, "}{");
				}
			}
			/*case 'y', 'Y': {
			}*/
			case 'z', 'Z': {
				StrCat(newMessage, length, "2");
			}
			default: {
				StrCat(newMessage, length, message[i]);
			}
		}
		StrCat(newMessage, length, "\0");
	}

	// Print message
	PrintToServer("say : %s", newMessage);

	return Plugin_Handled;
}

