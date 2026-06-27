/*
* This file is part of Project SkyFire https://www.projectskyfire.org.
* See LICENSE.md file for Copyright information
*/

#include "Define.h"
#include "PlayerDump.h"

#include <fstream>
#include <iostream>
#include <string>
#include <vector>

namespace
{
    bool Expect(bool condition, char const* message)
    {
        if (!condition)
            std::cerr << message << '\n';

        return condition;
    }

    std::string Trim(std::string const& value)
    {
        std::string::size_type first = value.find_first_not_of(" \t\r\n");
        if (first == std::string::npos)
            return "";

        std::string::size_type last = value.find_last_not_of(" \t\r\n");
        return value.substr(first, last - first + 1);
    }

    std::vector<std::string> ReadTableColumns(std::string const& path, std::string const& tableName)
    {
        std::ifstream input(path.c_str());
        std::vector<std::string> columns;

        if (!input)
        {
            std::cerr << "Could not open schema file: " << path << '\n';
            return columns;
        }

        std::string const createPrefix = "CREATE TABLE `" + tableName + "` (";
        std::string line;
        bool inTable = false;

        while (std::getline(input, line))
        {
            std::string const trimmed = Trim(line);

            if (!inTable)
            {
                if (trimmed == createPrefix)
                    inTable = true;

                continue;
            }

            if (!trimmed.empty() && trimmed[0] == ')')
                break;

            if (trimmed.empty() || trimmed[0] != '`')
                continue;

            std::string::size_type secondBacktick = trimmed.find('`', 1);
            if (secondBacktick == std::string::npos)
                continue;

            columns.push_back(trimmed.substr(1, secondBacktick - 1));
        }

        return columns;
    }

    bool ExpectField(std::vector<std::string> const& columns, uint32 oneBasedPosition, char const* expectedName)
    {
        if (!Expect(oneBasedPosition > 0, "Column positions are one-based and must be non-zero"))
            return false;

        if (columns.size() < oneBasedPosition)
        {
            std::cerr << "Schema has no column at position " << oneBasedPosition
                      << " for expected field `" << expectedName << "`\n";
            return false;
        }

        std::string const& actualName = columns[oneBasedPosition - 1];
        if (actualName == expectedName)
            return true;

        std::cerr << "Column position " << oneBasedPosition << " expected `"
                  << expectedName << "` but found `" << actualName << "`\n";
        return false;
    }

    bool TestCharacterDumpColumnPositionsMatchSchema()
    {
        std::vector<std::string> columns =
            ReadTableColumns(std::string(SKYFIRE_SOURCE_DIR) + "/sql/base/characters_database.sql", "characters");

        bool passed = true;
        passed &= Expect(!columns.empty(), "characters table columns should be discovered");
        passed &= ExpectField(columns, Skyfire::PlayerDump::CharacterFields::Guid, "guid");
        passed &= ExpectField(columns, Skyfire::PlayerDump::CharacterFields::Account, "account");
        passed &= ExpectField(columns, Skyfire::PlayerDump::CharacterFields::Name, "name");
        passed &= ExpectField(columns, Skyfire::PlayerDump::CharacterFields::Race, "race");
        passed &= ExpectField(columns, Skyfire::PlayerDump::CharacterFields::Class, "class");
        passed &= ExpectField(columns, Skyfire::PlayerDump::CharacterFields::Gender, "gender");
        passed &= ExpectField(columns, Skyfire::PlayerDump::CharacterFields::Level, "level");
        passed &= ExpectField(columns, Skyfire::PlayerDump::CharacterFields::AtLogin, "at_login");
        passed &= ExpectField(columns, Skyfire::PlayerDump::CharacterFields::DeleteInfosAccount, "deleteInfos_Account");
        passed &= ExpectField(columns, Skyfire::PlayerDump::CharacterFields::DeleteInfosName, "deleteInfos_Name");
        passed &= ExpectField(columns, Skyfire::PlayerDump::CharacterFields::DeleteDate, "deleteDate");

        return passed;
    }

    bool TestPetDeclinedNameColumnPositionsMatchSchema()
    {
        std::vector<std::string> columns =
            ReadTableColumns(std::string(SKYFIRE_SOURCE_DIR) + "/sql/base/characters_database.sql", "character_pet_declinedname");

        bool passed = true;
        passed &= Expect(!columns.empty(), "character_pet_declinedname table columns should be discovered");
        passed &= ExpectField(columns, Skyfire::PlayerDump::PetDeclinedNameFields::Id, "id");
        passed &= ExpectField(columns, Skyfire::PlayerDump::PetDeclinedNameFields::Owner, "owner");
        passed &= Expect(DTT_PET_DECLINEDNAME != DTT_PET, "Pet declined names need a distinct dump remap type");

        return passed;
    }

    bool TestCharacterPetColumnPositionsMatchSchema()
    {
        std::vector<std::string> columns =
            ReadTableColumns(std::string(SKYFIRE_SOURCE_DIR) + "/sql/base/characters_database.sql", "character_pet");

        bool passed = true;
        passed &= Expect(!columns.empty(), "character_pet table columns should be discovered");
        passed &= ExpectField(columns, Skyfire::PlayerDump::PetFields::Id, "id");
        passed &= ExpectField(columns, Skyfire::PlayerDump::PetFields::Owner, "owner");
        passed &= ExpectField(columns, 12, "active");

        return passed;
    }
}

int main()
{
    bool passed = true;

    passed &= TestCharacterDumpColumnPositionsMatchSchema();
    passed &= TestCharacterPetColumnPositionsMatchSchema();
    passed &= TestPetDeclinedNameColumnPositionsMatchSchema();

    return passed ? 0 : 1;
}
