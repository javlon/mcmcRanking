#' @export
mcmc <- function(mat, name, likelihood, fun){
  if(!is.matrix(mat)) stop("mat must be matrix.")
  if(!is.numeric(mat)) stop("mat mus be numeric vector.")
  if(!is.character(name)) stop("name must be character vector.")
  if(!is.numeric(likelihood)) stop("likelihood mus be numeric vector.")
  if(!is.function(fun)) stop("fun must be a function.")
  structure(list(mat = mat, name = name, likelihood = likelihood, fun = fun), class = "MCMC")
}

check_arguments <- function(graph, module_size){
  if(module_size > gorder(graph))
    stop("graph size less than required module size.")
}

#' Connected subgraph from uniform distribution.
#'
#' Generates a connected subgraph using Markov chain Monte Carlo (MCMC) method.
#'
#' @param graph An object of type \code{igraph} with \code{lieklihood} field in vertices.
#' @param module_size The size of subgraph.
#' @param iter Number of iterations.
#' @return Vector of vertex names of connected subgraph.
#' @seealso \code{\link{mcmc_sample}, \link{mcmc_onelong}}
#' @import igraph
#' @export
mcmc_subgraph <- function(graph, module_size, iter) {
  check_arguments(graph, module_size)
  edges <- data.frame(as_edgelist(graph, names = F)[,1:2] - 1)
  colnames(edges) <- c("from", "to")
  args <- c(nodes_size=length(V(graph)), module_size=module_size, iter=iter)
  res <- mcmc_subgraph_internal(edges, args) + 1
  return(V(graph)$name[res])
}

#' Set of connected subgraphs from uniform distribution.
#'
#' Generates set of independent subgraphs using Markov chain Monte Carlo (MCMC) method.
#'
#' @inheritParams mcmc_subgraph
#' @param times Number of subgraphs.
#' @return Object of type MCMC.
#' @seealso \code{\link{mcmc_subgraph}, \link{mcmc_onelong}}
#' @import igraph
#' @export
mcmc_sample <- function(graph, module_size, iter, times = 1, fun = function(x) x) {
  check_arguments(graph, module_size)
  edges <- data.frame(as_edgelist(graph, names = F)[,1:2] - 1)
  colnames(edges) <- c("from", "to")
  nodes <- data.frame(name=as.vector(V(graph)) - 1, likelihood = vapply(V(graph)$likelihood, fun, 1))
  args <- c(module_size=module_size, iter=iter, times=times)
  res <- mcmc_sample_internal(edges, nodes, args) + 1
  ret <- mcmc(matrix(res, ncol = module_size, byrow = T), V(graph)$name, V(graph)$likelihood, fun)
  return(ret)
}

#' Set of connected subgraphs.
#'
#' Generates set of subgraphs using Markov chain Monte Carlo (MCMC) method.
#'
#' @param graph An object of type \code{igraph} with \code{lieklihood} field in vertices.
#' @param module_size The size of subgraph.
#' @param start Starting with this iteration, we write down all states of the Markov process.
#' @param end Number of iterations.
#' @return Object of type MCMC.
#' @seealso \code{\link{mcmc_subgraph}, \link{mcmc_sample}}
#' @import igraph
#' @export
mcmc_onelong <- function(graph, module_size, start, end, fun = function(x) x) {
  check_arguments(graph, module_size)
  edges <- data.frame(as_edgelist(graph, names = F)[,1:2] - 1)
  colnames(edges) <- c("from", "to")
  nodes <- data.frame(name=as.vector(V(graph)) - 1, likelihood = vapply(V(graph)$likelihood, fun, 1))
  args <- c(module_size=module_size, start=start, end=end)
  res <- mcmc_onelong_internal(edges, nodes, args) + 1
  ret <- mcmc(matrix(res, ncol = module_size, byrow = T), V(graph)$name, V(graph)$likelihood, fun)
  return(ret)
}


#' Frequency of vertices.
#'
#' The frequency of occurrenceof vertices in one long run of method Markov chain Monte Carlo (MCMC).
#'
#' @param graph An object of type \code{igraph} with \code{lieklihood} field in vertices.
#' @param module_size The size of subgraph.
#' @param start Starting with this iteration, we write down all states of the Markov process.
#' @param end Number of iterations.
#' @return Named frequency vector.
#' @seealso \code{\link{mcmc_onelong}, \link{mcmc_subgraph}, \link{mcmc_sample}}
#' @import igraph
#' @export
mcmc_onelong_frequency <- function(graph, module_size, start, end, fun = function(x) x) {
  check_arguments(graph, module_size)
  edges <- data.frame(as_edgelist(graph, names = F)[,1:2] - 1)
  colnames(edges) <- c("from", "to")
  nodes <- data.frame(name=as.vector(V(graph)) - 1, likelihood = vapply(V(graph)$likelihood, fun, 1))
  args <- c(module_size=module_size, start=start, end=end)
  res <- mcmc_onelong_frequency_internal(edges, nodes, args)
  names(res) <- V(graph)$name
  return(res)
}


#' Vertex probability.
#'
#' Accurate estimate of vertex probability using all connected subgraphs.
#'
#' @param graph An object of type \code{igraph} with \code{lieklihood} field in vertices.
#' @return Named vector of probabilites.
#' @details Time complexity of method is \strong{exponential}. Use it only for the graphs of size less than 30.
#' @seealso \code{\link{get_prob}}
#' @import igraph
#' @export
real_prob <- function(graph) {
  edges <- data.frame(as_edgelist(graph, names = F)[,1:2] - 1)
  colnames(edges) <- c("from", "to")
  nodes <- data.frame(name=as.vector(V(graph)) - 1, likelihood = V(graph)$likelihood)

  res <- real_prob_internal(edges, nodes)
  names(res) <- V(graph)$name
  return(res)
}

#' Frequency of vertecies.
#'
#' Calculates the frequency of occurences of vertices in matrix object.
#'
#' @param mcmcObj Object of type MCMC.
#' @param inds Index numbers of rows involved in the calculation.
#' @return Named vector of frequency.
#' @seealso \code{\link{get_prob}}
#' @import igraph
#' @export
get_frequency <- function(mcmcObj, inds = seq_len(nrow(mcmcObj))){
  freq <- tabulate(mcmcObj$mat[inds,], length(mcmcObj$name))
  names(freq) <- mcmcObj$name
  return(freq)
}

#' Vertex probability using MCMC.
#'
#' Calculates the probability of vertices using its frequency of occurence in matrix object.
#'
#' @param mcmcObj Object of type MCMC.
#' @return list.
#' @seealso \code{\link{get_frequency}}
#' @export
get_not_prob <- function(mcmcObject){
  likelihood_node <- numeric(length(mcmcObject$name))
  names(likelihood_node) <- mcmcObject$name
  llh_row <- mcmcObject$llh_row
  mid_llh <- (max(llh_row) + min(llh_row))/2
  likelihood_row <- sapply(llh_row, function(x) exp(x - mid_llh) / mcmcObject$fun(exp(x - mid_llh)))
  likelihood_sum <- accurate_sum(likelihood_row)
  id_to_rows <- lapply(seq_along(likelihood_node), function(x) numeric())
  for(i in 1:nrow(mcmcObject$mat)){
    for(j in mcmcObject$mat[i,]){
      id_to_rows[[j]] <- c(id_to_rows[[j]], i)
    }
  }
  for(i in seq_along(likelihood_node)){
    likelihood_node[i] <- accurate_sum(likelihood_row[-id_to_rows[[i]]])
  }
  probs <- likelihood_node / likelihood_sum
  return(list(
    q = probs,
    likelihood_node = likelihood_node,
    likelihood_row = likelihood_row,
    sum = likelihood_sum,
    id_to_rows = id_to_rows))
}

get_inverse_likelihood <- function(graph, mat, inds = seq_len(nrow(mat))){
  inverse_likelihood <- 1 / apply(matrix(V(graph)[mat[inds,]]$likelihood, ncol = ncol(mat), byrow = F), 1, prod)
  inverse_likelihood <- sort(inverse_likelihood)
  return(sum(inverse_likelihood)/length(inds))
}

get_not_in_prob <- function(graph, module_size, start, end){
  likelihood <- V(graph)$likelihood
  n <- length(V(graph))

  mat <- mcmc_onelong(graph, module_size, start, end)
  mean_inv_lh <- get_inverse_likelihood(graph, mat)

  V(graph)$likelihood <- 1
  mat_uniform <- mcmc_onelong(graph, module_size, start, end)
  part_wo_node <- 1 - (table(mat_uniform) / nrow(mat_uniform))


  probs <- numeric(n);
  names(probs) <- V(graph)$name
  for(node in V(graph)$name){
    V(graph)$likelihood <- likelihood
    V(graph)$likelihood[V(graph)$name %in% node] <- 1e-300
    mat_node <- mcmc_onelong(graph, module_size, start, end)
    inds_wo_node <- which(apply(mat_node, 1, function(x) !any(x %in% node)))
    mean_inv_lh_wo_n <- get_inverse_likelihood(graph, mat_node, inds_wo_node)

    probs[node] <- mean_inv_lh / (mean_inv_lh_wo_n * part_wo_node[node])
  }
  V(graph)$likelihood <- likelihood
  return(probs)
}