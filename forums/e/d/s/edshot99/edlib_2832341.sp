/*
 * edlib rev03 - Library of functions that I need in multiple plugins.
 * Copyright (c) 2021, 2022, 2023 Ed <ed@groovyexpress.com>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

/*
 *  TODO:
 *  1. Implement a way to replace \x01 characters in translations with the real color.
 *     I just do it the manual way with a text editor, but I am pretty sure other people don't want to do that.
 */

#define EDLIBBUFFERSIZE 512

//// 
//// PrintToChatAllTranslated
//// 
public void PrintToChatAllTranslated(char[] textToTranslate, char[] prefix, char[] postfix)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}

public void PrintToChatAllTranslated1I(char[] textToTranslate, char[] prefix, char[] postfix, int param1)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}

public void PrintToChatAllTranslated1I1C(char[] textToTranslate, char[] prefix, char[] postfix, int param1, char[] param2)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, param2, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}

public void PrintToChatAllTranslated2I(char[] textToTranslate, char[] prefix, char[] postfix, int param1, int param2)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, param2, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}

public void PrintToChatAllTranslated3I(char[] textToTranslate, char[] prefix, char[] postfix, int param1, int param2, int param3)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, param2, param3, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}

public void PrintToChatAllTranslated3I2C(char[] textToTranslate, char[] prefix, char[] postfix, int param1, int param2, int param3, char[] param4, char[] param5)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, param2, param3, param4, param5, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}

public void PrintToChatAllTranslated2I1C(char[] textToTranslate, char[] prefix, char[] postfix, int param1, int param2, char[] param3)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, param2, param3, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}

public void PrintToChatAllTranslated2I2C(char[] textToTranslate, char[] prefix, char[] postfix, int param1, int param2, char[] param3, char[] param4)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, param2, param3, param4, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}

public void PrintToChatAllTranslated1C(char[] textToTranslate, char[] prefix, char[] postfix, char[] param1)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}

public void PrintToChatAllTranslated1C1I(char[] textToTranslate, char[] prefix, char[] postfix, char[] param1, int param2)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, param2, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}

public void PrintToChatAllTranslated2C(char[] textToTranslate, char[] prefix, char[] postfix, char[] param1, char[] param2)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, param2, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}

public void PrintToChatAllTranslated3C(char[] textToTranslate, char[] prefix, char[] postfix, char[] param1, char[] param2, char[] param3)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, param2, param3, postfix);
			PrintToChat(p, edlib_buf);
		}
	}
}


//// 
//// PrintHintTextToAllTranslated
//// 
public void PrintHintTextToAllTranslated(char[] textToTranslate, char[] prefix, char[] postfix)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, postfix);
			PrintHintText(p, edlib_buf);
		}
	}
}

public void PrintHintTextToAllTranslated2C(char[] textToTranslate, char[] prefix, char[] postfix, char[] param1, char[] param2)
{
	char edlib_buf[EDLIBBUFFERSIZE];
	for (int p = 1; p <= MaxClients; p++)
	{
		if (IsClientConnected(p) && IsClientInGame(p) && !IsFakeClient(p))
		{
			Format(edlib_buf, sizeof(edlib_buf), "%s%T%s", prefix, textToTranslate, p, param1, param2, postfix);
			PrintHintText(p, edlib_buf);
		}
	}
}


//// 
//// CheatCommand
//// Thanks to Pan Xiaohai for this.
//// 
stock void CheatCommand(int client, char[] command, char[] parameter1, char[] parameter2, char[] parameter3)
{
	int userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, (flags & ~FCVAR_CHEAT));
	FakeClientCommand(client, "%s %s %s %s", command, parameter1, parameter2, parameter3);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}
