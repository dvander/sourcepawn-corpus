#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.2"

ConVar is_enabled, first_port, first_id, name, host_name, host_port;
char name_str[64];
char default_host_name[64];
char id[8];

public Plugin myinfo =
{
    name = "[L4D & L4D2] Set Server Name",
    description = "Set the server name with format text and add UTF-8 characters.",
    author = "MoRanYue",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2833897"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int error_len) {
	EngineVersion engine_version = GetEngineVersion();
	if (engine_version != Engine_Left4Dead && engine_version != Engine_Left4Dead2) {
		strcopy(error, error_len, "This plugin only supports Left 4 Dead and Left 4 Dead 2");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart() {
    is_enabled = CreateConVar("ssn_is_enabled", "1", "0 will disable the plugin, other number will enable it", FCVAR_NOTIFY);
    first_port = CreateConVar("ssn_first_port", "27015", "It affects {id} format item. {id} = ssn_first_id + hostport - ssn_first_port", FCVAR_NOTIFY);
    first_id = CreateConVar("ssn_first_id", "1", "It affects {id} format item. {id} = ssn_first_id + hostport - ssn_first_port", FCVAR_NOTIFY);
    name = CreateConVar("ssn_host_name", "Left 4 Dead 2 Server", "Server name format string. {id} = Server number", FCVAR_NOTIFY);
    CreateConVar("set_server_name_version", PLUGIN_VERSION, "Set Server Name version", FCVAR_NOTIFY | FCVAR_DONTRECORD);
    AutoExecConfig(true, "set_server_name");

    host_name = FindConVar("hostname");
    host_port = FindConVar("hostport");
    is_enabled.AddChangeHook(OnIsEnabledChange);
    name.AddChangeHook(OnConVarChange);
    host_port.AddChangeHook(OnConVarChange);
    first_port.AddChangeHook(OnConVarChange);
    first_id.AddChangeHook(OnConVarChange);

    host_name.GetString(default_host_name, sizeof(default_host_name));
    SetHostName();
}

public void OnIsEnabledChange(ConVar convar, const char[] oldValue, const char[] newValue) {
    if (convar.BoolValue) {
        SetHostName();
        return;
    }
    host_name.SetString(default_host_name, false, false);
}
public void OnConVarChange(ConVar convar, const char[] oldValue, const char[] newValue) {
	if (is_enabled.BoolValue) {
        SetHostName();
    }
}

void SetHostName() {
    IntToString(first_id.IntValue + host_port.IntValue - first_port.IntValue, id, sizeof(id));
    name.GetString(name_str, sizeof(name_str));
    char buf[128];
    EscapeUtf8Character(name_str, buf, sizeof(buf));
    ReplaceString(buf, sizeof(buf), "{id}", id, false);
    host_name.SetString(buf, false, false);
    PrintToServer("The server name has been set to \"%s\".", buf);
}

void EscapeUtf8Character(char[] str, char[] buf, int max_len) {
    int index = 0;
    int len = strlen(str);
    // PrintToServer("len = %d", len);
    for (int i = 0; i < len && index < max_len; i++) {
        // PrintToServer("buf[index - 1] = %c", index - 1 > 0 ? buf[index - 1] : ' ');
        // PrintToServer("index = %d", index);
        // PrintToServer("i = %d", i);
        char ch = str[i];
        // PrintToServer("ch = %c", ch);
        if (ch == '\\' && ++i < len) {
            ch = str[i];
            if ((ch == 'u' || ch == 'U') && i + 4 < len) {
                char hex[5];
                strcopy(hex, sizeof(hex), str[i + 1]);
                i += 4;
                int code_point = StringToInt(hex, 16);
                char utf8_ch[3];
                int utf8_len = CodePointToUtf8(code_point, utf8_ch);
                // PrintToServer("UTF-8 character: %s (%s)", hex, utf8_ch);
                for (int j = 0; j < utf8_len && index < max_len; j++) {
                    buf[index++] = utf8_ch[j];
                    // buf[index++] = '?';
                }
            }
            else {
                buf[index] = '\\';
                if (++index < max_len) {
                    buf[index++] = ch;
                }
            }
        }
        else {
            buf[index++] = ch;
        }
    }
    buf[index < max_len ? index : max_len - 1] = '\0';
}

int CodePointToUtf8(int code_point, char[] buf) {
    if (code_point <= 0x7F) {
        buf[0] = code_point;
        return 1;
    }
    else if (code_point <= 0x7FF) {
        buf[0] = 0xC0 | ((code_point >> 6) & 0x1F);
        buf[1] = 0x80 | (code_point & 0x3F);
        return 2;
    }
    else if (code_point <= 0xFFFF) {
        buf[0] = 0xE0 | ((code_point >> 12) & 0x0F);
        buf[1] = 0x80 | ((code_point >> 6) & 0x3F);
        buf[2] = 0x80 | (code_point & 0x3F);
        return 3;
    }
    return 0;
}