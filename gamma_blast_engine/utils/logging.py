import json
import time
import uuid
from starlette.types import ASGIApp, Scope, Receive, Send, Message

class RequestLogMiddleware:
    def __init__(self, app: ASGIApp, service: str = "GammaBlastEngine") -> None:
        self.app = app
        self.service = service

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope.get("type") != "http":
            await self.app(scope, receive, send)
            return

        request_id = str(uuid.uuid4())
        start = time.monotonic()

        async def send_wrapper(message: Message) -> None:
            if message["type"] == "http.response.start":
                # attach request-id to RESPONSE headers
                headers = list(message.get("headers", []))
                headers.append((b"x-request-id", request_id.encode()))
                message["headers"] = headers

                status_code = message.get("status", 0)
                elapsed_ms = (time.monotonic() - start) * 1000.0
                log = {
                    "service": self.service,
                    "request_id": request_id,
                    "method": scope.get("method"),
                    "path": scope.get("path"),
                    "status": status_code,
                    "elapsed_ms": round(elapsed_ms, 2),
                }
                print(json.dumps(log, separators=(",", ":")))
            await send(message)

        # pass through to the downstream app
        await self.app(scope, receive, send_wrapper)
