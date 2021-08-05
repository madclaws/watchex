# Changelog

# 0.1.1

- Fixed server dropping the connection for all players with same name if one of them exits.
- Added more tests that covers attack, multiple cases of respawn, World Supervision of Players
- Removed commented IO.inspect and other logs.
- Full implementation of World as a supervision for Player. Player is spawned by start_link now,
  and parent will be world, and when there are abnormal crashes World will take care of restarting the player with the last knwo position.

# 0.1.0
- Initial working release