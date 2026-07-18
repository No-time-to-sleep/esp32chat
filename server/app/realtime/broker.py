from __future__ import annotations

import asyncio

from fastapi import WebSocket


class ChatRealtimeBroker:
    MAX_CONNECTIONS = 50

    def __init__(self) -> None:
        self._lock = asyncio.Lock()
        self._rooms: dict[int, set[WebSocket]] = {}
        self._ws_users: dict[WebSocket, int] = {}

    def active_count(self) -> int:
        return sum(len(r) for r in self._rooms.values())

    def online_users(self) -> list[int]:
        return list(set(self._ws_users.values()))

    async def connect(self, *, chat_id: int, websocket: WebSocket, user_id: int = 0) -> None:
        if self.active_count() >= self.MAX_CONNECTIONS:
            await websocket.close(code=4503, reason="too many connections")
            return
        async with self._lock:
            room = self._rooms.setdefault(chat_id, set())
            room.add(websocket)
            self._ws_users[websocket] = user_id

    async def disconnect(self, *, chat_id: int, websocket: WebSocket) -> None:
        async with self._lock:
            room = self._rooms.get(chat_id)
            if room is None:
                return
            room.discard(websocket)
            self._ws_users.pop(websocket, None)
            if not room:
                self._rooms.pop(chat_id, None)

    async def publish(self, *, chat_id: int, event: dict[str, object]) -> int:
        async with self._lock:
            targets = list(self._rooms.get(chat_id, set()))

        delivered = 0
        dead: list[WebSocket] = []

        for websocket in targets:
            try:
                await websocket.send_json(event)
                delivered += 1
            except Exception:
                dead.append(websocket)

        if dead:
            async with self._lock:
                room = self._rooms.get(chat_id)
                if room is not None:
                    for websocket in dead:
                        room.discard(websocket)
                        self._ws_users.pop(websocket, None)
                    if not room:
                        self._rooms.pop(chat_id, None)

        return delivered

    async def connection_count(self, *, chat_id: int) -> int:
        async with self._lock:
            return len(self._rooms.get(chat_id, set()))
