// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import { TournamentTypes } from "../types/Types.sol";

// Pellar + LightLink 2022

interface ITournamentRoute {
  // bind service processing tournament
  function bindService(uint64 _ID, address _service) external;

  // join tournament
  function joinTournament(
    uint64 _serviceID,
    bytes memory _signature,
    bytes memory _params
  ) external;

  // create tournament
  function createTournament(
    uint64 _serviceID,
    string[] memory _key,
    TournamentTypes.TournamentConfigs[] memory configs,
    TournamentTypes.TournamentRestrictions[] memory _restrictions
  ) external;

  // update tournament
  function updateTournamentConfigs(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentConfigs memory configs
  ) external;

  function updateTournamentRestrictions(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.TournamentRestrictions memory _restrictions
  ) external;

  function updateTournamentTopUp(uint64 _serviceID, TournamentTypes.TopupDto[] memory _tournaments) external;

  // cancel tournament
  function cancelTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    bytes memory _params
  ) external;

  function eligibleJoinTournament(uint64 _serviceID, uint64 _tournamentID, uint256 _championID) external view returns (bool, string memory);

  function completeTournament(
    uint64 _serviceID,
    uint64 _tournamentID,
    TournamentTypes.Warrior[] memory _warriors,
    TournamentTypes.EloDto[] memory _championsElo,
    bytes memory
  ) external;
}
