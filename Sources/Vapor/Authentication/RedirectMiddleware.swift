extension Authenticatable {
    /// Basic middleware to redirect unauthenticated requests to the supplied path
    ///
    /// - parameters:
    ///    - path: The path to redirect to if the request is not authenticated
    public static func redirectMiddleware(path: String) -> Middleware {
        self.redirectMiddleware(makePath: { _ in path })
    }
    
    /// Basic middleware to redirect unauthenticated requests to the supplied path
    ///
    /// - parameters:
    ///    - makePath: The closure that returns the redirect path based on the given `Request` object
    public static func redirectMiddleware(makePath: @escaping (Request) -> String) -> Middleware {
        RedirectMiddleware<Self>(Self.self, makePath: makePath)
    }
}


private final class RedirectMiddleware<A>: Middleware
    where A: Authenticatable
{
    let makePath: (Request) -> String
    
    init(_ authenticatableType: A.Type = A.self, makePath: @escaping (Request) -> String) {
        self.makePath = makePath
    }

    /// See Middleware.respond
    func respond(to req: Request, chainingTo next: Responder) -> EventLoopFuture<Response> {
        if req.auth.has(A.self) {
            return next.respond(to: req)
        }

        let redirect = req.redirect(to: self.makePath(req))
        return req.eventLoop.makeSucceededFuture(redirect)
    }
}