import networkx as nx
import sys
#import pylab
import copy
#import pydot

# Read the contact matrix as a graph (This includes ++ and -- contacts too)
G=nx.Graph(nx.drawing.nx_pydot.read_dot('contact.dot'))
# Renumber starting from 1 instead of 0
#G=nx.relabel.convert_node_labels_to_integers(Plm, first_label=1, ordering='default', label_attribute=None)

# Remove anion-anion and cation-cation contacts from contact list
O=copy.deepcopy(G)
E=copy.deepcopy(G)
O.remove_nodes_from(tuple(str(x) for x in range(0,O.number_of_nodes()+3,2)))
E.remove_nodes_from(tuple(str(x) for x in range(1,E.number_of_nodes()+3,2)))
G.remove_edges_from(O.edges())
G.remove_edges_from(E.edges())
print(int(nx.algorithms.components.is_connected(G)))


sys.stdout = open("mst", "w")
if nx.algorithms.components.is_connected(G):
  MST=nx.algorithms.tree.minimum_spanning_tree(G)
  for line in nx.generate_edgelist(MST, data=False):print(line)

sys.stdout.close()


# Draw
#import matplotlib.pyplot as plt
#pos = nx.spring_layout(MST)
#labels=nx.draw_networkx_labels(MST,pos=pos)
#nx.draw_networkx_nodes(MST, pos)
#nx.draw_networkx_edges(MST, pos)
#nx.draw_networkx_labels(MST, pos)
#plt.show()
