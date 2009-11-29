`ordistep` <-
    function(object, scope, direction =c("both", "backward", "forward"),
             Pin = 0.05, Pout = 0.1, pstep = 100, perm.max = 1000,
             steps=50, trace = TRUE, ...)
{
    if (!inherits(object, "cca"))
        stop("function can be only used with 'cca' and related objects")
    ## handling 'direction' and 'scope' directly copied from
    ## stats::step()
    md <- missing(direction)
    direction <- match.arg(direction)
    backward <- direction == "both" | direction == "backward"
    forward <- direction == "both" | direction == "forward"
    ffac <- attr(terms(object), "factors")
    if (missing(scope)) {
        fdrop <- numeric(0)
        fadd <- ffac
        if (md) 
            forward <- FALSE
    }
    else {
        if (is.list(scope)) {
            fdrop <- if (!is.null(fdrop <- scope$lower)) 
                attr(terms(update.formula(object, fdrop)), "factors")
            else numeric(0)
            fadd <- if (!is.null(fadd <- scope$upper)) 
                attr(terms(update.formula(object, fadd)), "factors")
        }
        else {
            fadd <- if (!is.null(fadd <- scope)) 
                attr(terms(update.formula(object, scope)), "factors")
            fdrop <- numeric(0L)
        }
    }
    scope <- factor.scope(ffac, list(add = fadd, drop = fdrop))
    mod <- object
    for (i in 1:steps){
        change <- NULL
        ## Consider dropping
        if (backward && length(scope$drop)) {
            aod <- drop1(mod, scope = scope$drop, test="perm", pstep = pstep,
                         perm.max = perm.max, alpha = Pout, trace = trace, ...)
            aod <- aod[-1,]
            o <- order(-aod[,5], aod[,4], aod[,2])
            aod <- aod[o,]
            rownames(aod) <- paste("-", rownames(aod), sep = " ")
            if (trace) {
                cat("\n")
                print(aod)
            }
            if (aod[1,5] > Pout) {
                change <- rownames(aod)[1]
                mod <- eval.parent(update(mod, paste("~  .", change)))
                scope <- factor.scope(attr(terms(mod), "factors"),
                                      list(add = fadd, drop = fdrop))
                if (trace) {
                    cat("\n")
                    print(mod$call)
                }
            }
        }
        ## Consider adding
        if (forward && length(scope$add)) {
            aod <- add1(mod, scope = scope$add, test = "perm", pstep = pstep,
                        perm.max = perm.max, alpha = Pin, trace = trace, ...)
            aod <- aod[-1,]
            o <- order(aod[,5], aod[,4], aod[,2])
            aod <- aod[o,]
            rownames(aod) <- paste("+", rownames(aod), sep = " ")
            if (trace) {
                cat("\n")
                print(aod)
            }
            if (aod[1,5] <= Pin) {
                change <- rownames(aod)[1]
                mod <- eval.parent(update(mod, paste( "~  .",change)))
                scope <- factor.scope(attr(terms(mod), "factors"),
                                      list(add = fadd, drop = fdrop))
                if (trace) {
                    cat("\n")
                    print(mod$call)
                }
            }
        }
        ## No drop, no add: done
        if (is.null(change))
            break
    }
    cat("\n")
    mod
}