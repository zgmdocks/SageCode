include 'sage/ext/stdsage.pxi'
include 'sage/ext/cdefs.pxi'
include 'cysignals/signals.pxi'

import os
import operator as op
import time
import signing.spyx
from sage.all import *

moreDebug = True
edgesLeft = True

def ncr(n, r):
    r = min(r, n-r)
    if r == 0: return 1
    numer = reduce(op.mul, xrange(n, n-r, -1))
    denom = reduce(op.mul, xrange(1, r+1))
    return numer//denom

# check takes a graph G as input and returns true if the 
# graph satisfies all properties that would make
# it a good candidate for the method used in John 
# Sinkovic's Paper to find an inertia bound that
# is not tight
def check(G):
    if moreDebug:
        t0 = time.clock()
    alpha = len(G.independent_set())
    numVertices = len(G)
    if 2*alpha+1 > numVertices:
        print "alpha too large"
        return False
    if moreDebug:
        print "alpha is {}".format(alpha)
        print "numVerties is {}".format(numVertices)
        print "number of combinations will be {}".format(ncr(numVertices,2*alpha+1))
    if not is_alpha_critical(G):
        print "alpha critical"
        return False
    path = G.hamiltonian_path()
    if not path:
        print "no hamiltionian"
        path = G.random_spanning_tree()
    #if not G.is_arc_transitive():
        #return False
    subgraphs = set()
    trianglesCheck = set()
    for combo in Combinations(numVertices,2*alpha+1):
        I = G.subgraph(combo,immutable=true)
        #st = g.canonical_label().graph6_string()
        #this next while loop will delete all pendants of g,
        #then check if the resulting g is a: a single odd cycle
        # or b: a disjoint union of odd cycles. if it is in category
        # a, then it is added to trainglesCheck list, and if it is in b,
        # it is added to subgraphs list
        h = G.subgraph(combo)
        # this changed variable is necessary because when we iterate through the
        # vertices, we are deleting some and creating new pendants that we need
        # to delete also, but if we already iterated over that vertice, then
        # we won't realize that it still needs to be deleted so we need to
        # keep iterating over the vertices until we get to a point where we don't
        # find and delete any new pendants
        changed = True
        while changed:
            changed = False
            for v in h.vertex_iterator():
                if len(h[v]) == 1:
                    changed = True
                    h.delete_vertex(h[v][0])
                    h.delete_vertex(v)
                    break
        if h.is_cycle() and h.order()%2 == 1:
            copy = h.copy(immutable=true)
            trianglesCheck.add(copy)
        components = h.connected_components_subgraphs()
        if not components:
            break
        continue_loop = False
        for com in components:
            if (not com.is_cycle()) or (not com.order()%2 == 1):
                continue_loop = True 
                # need continue_loop because I want to continue out of outer for
                # loop, but using continue now will only continue out of 
                # the inner for loop
                break
        if continue_loop:
            continue
        # if we make it to this point, every component was an odd cycle
        subgraphs.add(I)
    if moreDebug:
        print "number of subgraphs: {}".format(len(subgraphs))
        print "**************************** {}".format(time.clock() - t0)
    T = graphs.CompleteGraph(3)
    Triangles = contained(G,T,trianglesCheck)
    if moreDebug:
        print "number of triangles to use: {}".format(len(Triangles))
    if moreDebug:
        print "number of triangles: {}".format(len(Triangles))
    if not Triangles:
        print "contained"
        return False
    # finished preliminary check, now to check signs
    if debug:
        print "Check passed"
        print len(subgraphs)
    for e in G.edge_iterator(labels=false):
        temp1 = e[0]
        temp2 = e[1]
        G.delete_edge(e)
        if path.has_edge(e):
            if debug:
                print e
            G.add_edge((temp1,temp2,1))
        else:
            G.add_edge((temp1,temp2,10))
    M1 = G.weighted_adjacency_matrix()
    M2 = G.weighted_adjacency_matrix()
    if debug:
        print M1
    if not signing(G,M1,subgraphs,1,Triangles):
        return False
    if moreDebug:
        print "************* Positive Signing found a contradiction **********************"
    if not signing(G,M2,subgraphs,-1,Triangles):
        return False
    if debug:
        pathGraphic = path.plot()
        pathGraphic.save('path.png')
        os.system('open path.png')
    return True


# contained returns true if the each triangle in G is
# contained in at least one subgraph of the form SubGraph and
# false otherwise
def contained(G, Triangle, SubGraphs):
    Triangles = set()
    #calculates the total number of triangles in G
    for triangle in G.subgraph_search_iterator(Triangle,induced = true):
        for s in SubGraphs:
            if set(triangle).issubset(set(s)):
                Triangles.add(tuple(triangle))
                break
    return Triangles



# is_alpha_critical returns true if the graph G is alpha critical
def is_alpha_critical(G):
    alpha=len(G.independent_set())
    for i in G.edges():
        H=G.copy()
        H.delete_edge(i)
        if len(H.independent_set())==alpha:
            return False
    return True

g = Graph("W~ffCIWaONGYEhEYDRAH_KT?hEIBYogboAqxBBlAGEicPKt")
#graphic = g.plot()
#graphic.save('output.png')
#os.system('open output.png')
print check(g)