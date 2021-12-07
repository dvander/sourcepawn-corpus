/**
 * vim: set ts=4 :
 * =============================================================================
 * cURL Write Function Example
 * 
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */



#pragma semicolon 1

#pragma dynamic 32767 // Without this line will crash server!!

#include <sourcemod>
#include <cURL>

#define USE_THREAD				1
#define TEST_FOLDER				"data/curl_test"
	
	
new CURL_Default_opt[][2] = {
#if USE_THREAD
	{_:CURLOPT_NOSIGNAL,1},
#endif
	{_:CURLOPT_NOPROGRESS,1},
	{_:CURLOPT_TIMEOUT,30},
	{_:CURLOPT_CONNECTTIMEOUT,60},
	{_:CURLOPT_VERBOSE,0}
};

#define CURL_DEFAULT_OPT(%1) curl_easy_setopt_int_array(%1, CURL_Default_opt, sizeof(CURL_Default_opt))

public Plugin:myinfo = 
{
	name = "cURL write function test",
	author = "Raydan",
	description = "cURL write function test",
	version = "1.0.0.0",
	url = "http://www.ZombieX2.net/"
};

new String:curl_test_path[512];
new Handle:test_1_file = INVALID_HANDLE;
new Handle:test_2_file = INVALID_HANDLE;

public OnPluginStart()
{
	//PluginInit();
	RegServerCmd("curl_test", curl_write_func_test);
	RegServerCmd("test_all", Command_Test);
}

public PluginInit()
{
	BuildPath(Path_SM, curl_test_path, sizeof(curl_test_path), TEST_FOLDER);
	new Handle:test_folder_handle = OpenDirectory(curl_test_path);
	if(test_folder_handle == INVALID_HANDLE)
	{
		if(!CreateDirectory(curl_test_path, 557))
		{
			SetFailState("Unable Create folder %s",TEST_FOLDER);
			return;
		}
	} else {
		new String:buffer[128];
		new String:path[512];
		new FileType:type;
		while(ReadDirEntry(test_folder_handle, buffer, sizeof(buffer), type))
		{
			if(type != FileType_File)
				continue;
			
			BuildPath(Path_SM, path, sizeof(path), "%s/%s", TEST_FOLDER, buffer);
			DeleteFile(path);
		}
		CloseHandle(test_folder_handle);
	}
}

public Action:curl_write_func_test(args)
{
	PrintToServer("Start testing...");

	Test_1();
	return Plugin_Handled;
}

public WriteHTMLFunction(Handle:hndl, const String:buffer[], const bytes, const nmemb)
{
	PrintTestDebug("WriteHTMLFunction - Got %d bytes", nmemb);

	WriteFileLine(test_1_file, buffer);
	return bytes*nmemb;
}

public Test_1()
{
	static test = 0;
	decl String:path[512];
	PrintTestDebug("Start Download a Web Page");
	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "page.log");
	test_1_file = OpenFile(path, "a");

	new Handle:curl = curl_easy_init();
	if(curl != INVALID_HANDLE)
	{
		CURL_DEFAULT_OPT(curl);
		curl_easy_setopt_function(curl, CURLOPT_WRITEFUNCTION, WriteHTMLFunction);
		curl_easy_setopt_string(curl, CURLOPT_URL, "google.com");
		new CURLcode:code = curl_load_opt(curl);
		if (code == CURLE_OK)
			ExecCURL(curl, ++test);
		else
		{
			new String:error_buffer[256];
			curl_easy_strerror(code, error_buffer, sizeof(error_buffer));
			PrintTestDebug("#%d FAIL - %s", ++test, error_buffer);
			CloseHandle(curl);
		}
	}
	else
	{
		PrintToServer("Unable Create Curl");
		CloseHandle(curl);
	}
}

public onComplete(Handle:hndl, CURLcode: code, any:data)
{
	if(code != CURLE_OK)
	{
		new String:error_buffer[256];
		curl_easy_strerror(code, error_buffer, sizeof(error_buffer));
		PrintTestDebug("#%d FAIL - %s", data, error_buffer);
	} else {
		PrintTestDebug("#%d Done", data);
	}
	

	if(test_1_file != INVALID_HANDLE)
		CloseHandle(test_1_file);
	test_1_file = INVALID_HANDLE;

	CloseHandle(hndl);
}

stock ExecCURL(Handle:curl, current_test)
{
#if USE_THREAD
	curl_easy_perform_thread(curl, onComplete, current_test);
#else
	new CURLcode:code = curl_load_opt(curl);
	if(code != CURLE_OK) {
		PrintTestCaseDebug(current_test, "curl_load_opt Error");
		PrintcUrlError(code);
		CloseHandle(curl);
		return;
	}
	
	code = curl_easy_perform(curl);
	
	onComplete(curl, code, current_test);

#endif
}

stock PrintTestDebug(const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 2);
	PrintToServer("[CURL FUNCTION Test] %s", buffer);
}


public Action:Timer_PrintMessageFiveTimes(Handle:timer)
{
    static numPrinted = 0;
    ServerCommand("curl_test");
    if (numPrinted == 1000)
    	return Plugin_Stop;
}


public Action:Command_Test(args)
{
    CreateTimer(0.01, Timer_PrintMessageFiveTimes, _, TIMER_REPEAT);
    return Plugin_Handled;
}