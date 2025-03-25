// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { Base } from "../common/Base.sol";
import { ITournamentRoute } from "../interfaces/ITournamentRoute.sol";

// Pellar + LightLink 2022

contract TRVTournamentRouteExtended is Base {
  uint256 public maxPerTxn = 4;
  address public tournamentRoute = 0xF681C909C16a0c5AA10308075144DC5666e936BE;

  function bindTournamentRouteAddress(address _tournamentRoute) external onlyRoler("bindTournamentRouteAddress") {
    tournamentRoute = _tournamentRoute;
  }

  function setupMaxPerTxn(uint256 _max) external onlyRoler("setupMaxPerTxn") {
    maxPerTxn = _max;
  }

  function joinTournaments(
    uint64[] memory _serviceIDs,
    bytes[] memory _signatures,
    bytes[] memory _params
  ) external {
    require(maxPerTxn >= _serviceIDs.length, "Exceed Max");
    require(_serviceIDs.length == _signatures.length, "Input mismatch");
    require(_serviceIDs.length == _params.length, "Input mismatch");

    uint256 size = _serviceIDs.length;
    for (uint256 i = 0; i < size; i++) {
      ITournamentRoute(tournamentRoute).joinTournament(_serviceIDs[i], _signatures[i], _params[i]);
    }
  }

  function eligibleJoinTournament(
    uint64[] memory _serviceIDs,
    uint64[] memory _tournamentIDs,
    uint256[] memory _championIDs
  ) public view returns (bool[] memory, string[] memory) {
    bool[] memory results = new bool[](_serviceIDs.length);
    string[] memory messages = new string[](_serviceIDs.length);

    uint256 size = _serviceIDs.length;
    for (uint256 i = 0; i < size; i++) {
      (bool eligible, string memory message) = ITournamentRoute(tournamentRoute).eligibleJoinTournament(_serviceIDs[i], _tournamentIDs[i], _championIDs[i]);
      results[i] = eligible;
      messages[i] = message;
    }

    return (results, messages);
  }
}
