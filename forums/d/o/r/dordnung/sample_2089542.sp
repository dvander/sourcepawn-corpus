#include <sourcemod>
#include <bigint>


#define FirstNumber      "40202D60B81C7"
#define SecondNumber     "207"


public OnPluginStart()
{
	decl String:resultString[1024];
	decl String:resultString2[512];
	decl String:resultString3[512];
	decl String:resultString4[512];
	decl String:resultString5[512];

	new Handle:firstNumber = BigInt_CreateFromString(FirstNumber, 16);
	new Handle:secondNumber = BigInt_CreateFromString(SecondNumber);
	new Handle:result;
	new Handle:g;
	new Handle:r;
	new Handle:s;


	// Test Steamid converter
	convertSteamid("STEAM_0:1:123456789");



	switch(BigInt_CompareTo(firstNumber, secondNumber))
	{
		case BigInt_LESSER:
		{
			PrintToServer("%s is lesser than %s", FirstNumber, SecondNumber);
		}
		case BigInt_EQUAL:
		{
			PrintToServer("%s is equal with %s", FirstNumber, SecondNumber);
		}
		case BigInt_GREATER:
		{
			PrintToServer("%s is greater than %s", FirstNumber, SecondNumber);
		}
		default:
		{
			PrintToServer("%s is greater than %s", FirstNumber, SecondNumber);
		}
	}


	switch(BigInt_GetSign(firstNumber))
	{
		case BigInt_NEGATIVE:
		{
			PrintToServer("%s is negative", FirstNumber);
		}
		case BigInt_ZERO:
		{
			PrintToServer("%s is zero", FirstNumber);
		}
		case BigInt_POSITIVE:
		{
			PrintToServer("%s is positive", FirstNumber);
		}
		default:
		{
			PrintToServer("%s is positive", FirstNumber);
		}
	}


	switch(BigInt_GetSign(secondNumber))
	{
		case BigInt_NEGATIVE:
		{
			PrintToServer("%s is negative", SecondNumber);
		}
		case BigInt_ZERO:
		{
			PrintToServer("%s is zero", SecondNumber);
		}
		case BigInt_POSITIVE:
		{
			PrintToServer("%s is positive", SecondNumber);
		}
		default:
		{
			PrintToServer("%s is positive", SecondNumber);
		}
	}


	BigInt_ToString(firstNumber, resultString, sizeof(resultString), 10);
	PrintToServer("%s in dec is: %s", FirstNumber, resultString);


	BigInt_Euclidean(firstNumber, secondNumber, g, r, s);
	BigInt_ToString(g, resultString3, sizeof(resultString3));
	BigInt_ToString(r, resultString4, sizeof(resultString4));
	BigInt_ToString(s, resultString5, sizeof(resultString5));
	PrintToServer("%s*%s + %s*%s == %s", resultString4, FirstNumber, resultString5, SecondNumber, resultString3);


	result = BigInt_Compute(firstNumber, secondNumber, BigInt_ADD);
	BigInt_ToString(result, resultString, sizeof(resultString));

	PrintToServer("%s + %s is %s", FirstNumber, SecondNumber, resultString);
	CloseHandle(result);


	result = BigInt_Compute(firstNumber, secondNumber, BigInt_SUBTRACT);
	BigInt_ToString(result, resultString, sizeof(resultString));

	PrintToServer("%s - %s is %s", FirstNumber, SecondNumber, resultString);
	CloseHandle(result);


	result = BigInt_Compute(firstNumber, secondNumber, BigInt_MULTIPLY);
	BigInt_ToString(result, resultString, sizeof(resultString));

	PrintToServer("%s * %s is %s", FirstNumber, SecondNumber, resultString);
	CloseHandle(result);


	result = BigInt_Compute(firstNumber, secondNumber, BigInt_DIVIDE);
	BigInt_Compute(firstNumber, secondNumber, BigInt_DIVIDE_REMAINDER, BigInt_OVERRIDE);

	BigInt_ToString(result, resultString, sizeof(resultString));
	BigInt_ToString(firstNumber, resultString2, sizeof(resultString2));

	PrintToServer("%s / %s is %s with remainder %s", FirstNumber, SecondNumber, resultString, resultString2);
	CloseHandle(result);

	CloseHandle(firstNumber);
	CloseHandle(secondNumber);
}



convertSteamid(const String:steam[])
{
	new String:steamid[64];
	decl String:parts[3][16];

	ExplodeString(steam, ":", parts, sizeof(parts), sizeof(parts[]))

	new Handle:bigint = BigInt_ComputeStrs("76561197960265728", parts[1], BigInt_ADD);
	new Handle:bigint2 = BigInt_ComputeIntStr(2, parts[2], BigInt_MULTIPLY);

	BigInt_Compute(bigint, bigint2, BigInt_ADD, BigInt_OVERRIDE);

	BigInt_ToString(bigint, steamid, sizeof(steamid));

	PrintToServer("Community of Steamid %s is %s", steam, steamid);

	CloseHandle(bigint);
	CloseHandle(bigint2);
}