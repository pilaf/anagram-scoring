
package Ana::Graph;
use Carp 'confess';
use strict;

=encoding utf8

=head1 NAME

C<Ana::Graph> – Graph algorithms for anagram detection and scoring

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Internals

The internal structure of a graph object is:

        [ Vnames, Vmap, Adj ]

The C<Vnames> component is an array of vertex names.
These should be distinct strings.

The C<Vmap> component is a hash that maps vertex names
to their indices in the C<Vnames> array.  That is,

        $Vmap->{$Vnames->[$i]}  === $i

for each C<$i> that is a legal index of C<Vnames>,
and
        $Vnames->[$Vmap->{$name}] === $name

for each vertex name in C<Vnames>.

The C<Adj> component is a two dimensional array
that expresses the adjacency relationship between vertices.
 should be a boolean true value if
the vertices numbered I<i> and I<j> are connected by an edge,
false otherwise.

C<< $Adj->[$i][$j] >> should in call cases
have the same truth value as C<< $Adj->[$j][$i] >>.

=head2 Methods

=head3 C<new_graph>

        my $graph = Ana::Graph->new_graph([ I<vertex-names>... ]);

Construct a new, totally disconnected graph with the specified vertex names.
To add edges, use C<add_edge> or C<add_edges>.

=cut

# new_graph([ vertex-names... ])
sub new_graph {
  my ($self, $vnames) = @_;
  $vnames //= [];
  my $class = ref($self) || $self;
  my @vnames = @$vnames;
  my %vmap = map { $vnames[$_] => $_ } 0 .. $#vnames;
  bless [ \@vnames, \%vmap, [] ] => $class;
}

=head3 C<V>

        my $vnames = $graph->V;

Returns the array of the graph's vertex names.

=head3 C<E>

        my $edges = $graph->E;
        for my $edge (@$edges) {
          print "There is an edge from vertex $edge->[0] to vertex $edge->[1]\n";
        }

Returns an array of the graphs edges.
Each edge is a two element array containing the names of the edge's two endpoints.
Each edge is included only once in the returned list.

In list context, the function returns a list of edges instead of an array.

=cut

sub V { $_[0][0] }
sub E {
  my ($self) = @_;
  my $adj = $self->adj;
  my @E;
  for my $i (0 .. $#$adj) {
    next unless my $adj_i = $adj->[$i];
    for my $j ($i+1 .. $#$adj) {
      push @E, [ $self->vnames($i, $j) ] if $adj_i->[$j];
    }
  }
  return wantarray ? @E : \@E;
}

=head3 C<adj>

        my $matrix = $graph->adj;

Returns the graph's adjacency matrix.

=cut

sub adj { $_[0][2] }

=head3 C<add_edge>

=head3 C<add_edges>

        $graph->add_edge([ $v1, $v2 ]);

        $graph->add_edges([ $v1, $v2 ], [ $v3, $v4 ], …);

Adds edges to the graph.
Each edge is specified as a two-element array containing the names
of the edge's two endpoints.

If an added edge is already in the graph, it is ignored.

=cut

sub add_edges {
  my ($self, @edges) = @_;
  $self->add_edge($_) for @edges;
}

sub add_edge {
  my ($self, $e) = @_;
  my ($v1, $v2) = $self->vi(@$e);
  $self->adj->[$v1][$v2] = 1;
  $self->adj->[$v2][$v1] = 1;
}

=head3 C<vi>

        my @indices = $self->vi( $v1, $v2, … );
        my $index = $self->vi( $v );

Returns the index number of the specified vertices,
suitable for indexing the adjacency matrix.

In scalar context, only one vertex name may be given.

If any vertices are unrecognized, throws an exception.

=cut

sub vi {
  my ($self, @vnames) = @_;
  confess "need array context for multiple arguments to ->vi()"
    if !wantarray() && @vnames > 1;
  my @vi;
  push @vi, $self->[1]{$_} // confess "Unknown vertex '$_'" for @vnames;
  wantarray ? @vi : $vi[0];
}

=head3 C<vnames>

        my @names = $self->vnames( $i1, $i2, … );

This is just a slice from the graph's vertex list.
Given vertex indices C<$i1> etc., returns the names of
those vertices.

=cut

sub vnames {
  my ($self, @indices) = @_;
  return ($self->V->@*)[@indices];
}

=head3 C<are_adjacent>

        my $bool = $graph->are_adjacent( $v1, $v2 );

Returns true if the two given vertices are connected by an edge,
false otherwise.

=cut

sub are_adjacent {
  my ($self, $v, $w) = @_;
  my ($vi, $wi) = $self->vi($v, $w);
  $self->adj->[$vi][$wi];
}

=head3 C<adjacent_any>

        my $bool = $graph->are_adjacent( $v, $v1, $v2, … );

Returns true if the first vertex C<$v> is adjacent to any of the other vertices
C<$v1, $v2, …>,
false otherwise.

=cut

sub adjacent_any {
  my ($self, $v, @set) = @_;
  for my $w (@set) {
    return 1 if $self->are_adjacent($v, $w);
  }
  return;
}

sub neighbors {
  my ($self, $v) = @_;
  my $adj_to = $self->adj->[$self->vi($v)] // [];
  return $self->vnames(grep $adj_to->[$_], 0 .. $#$adj_to);
}

# Remove all the neighbors of $v from @$vlist
# and return the result
sub remove_neighbors_of {
  my ($self, $v, $vlist) = @_;
  $DB::single = 1;
  my ($vi, @vli) = $self->vi($v, @$vlist);
  my $adj = $self->adj->[$vi];
  return [$self->vnames(grep ! $adj->[$_], @vli)];
}

# Given words A and B:
# the vertices are pairs (i, j) such that A[i] = B[j] and A[i+1] = B[j+1]
# two vertices are connected if the corresponding pair mappings are compatible
sub new_from_words {
  my ($class, $a, $b) = @_;
  my (@a) = split //, $a;
  my (@b) = split //, $b;

  my @V;
  for my $i (0 .. $#a-1) {
    for my $j (0 .. $#b-1) {
      if ($a[$i] eq $b[$j] && $a[$i+1] eq $b[$j+1]) {
        push @V, "$i,$j";
      }
    }
  }

  my $G = $class->new_graph(\@V);

  for my $q1 (0 .. $#V-1) {
    for my $q2 ($q1+1 .. $#V) {
      my ($i, $j) = split /,/, $V[$q1];
      my ($k, $l) = split /,/, $V[$q2];
      my $BAD = 0;
      if ($i == $k && $j != $l) { $BAD = 1 }
      elsif ($i+1 == $k && $j+1 != $l) { $BAD = 1 }
      elsif ($i+1 < $k && !disjoint([$j, $j+1], [$l, $l+1])) { $BAD = 1 }

      if ($BAD) {
        $G->add_edges( [ @V[$q1, $q2] ] );
      }
    }
  }

  return $G;
}

sub disjoint {
  my ($S, $T) = @_;
  for my $s (@$S) {
    for my $t (@$T) {
      return if $s eq $t;
    }
  }
  return 1;
}

sub to_dot_mis {
  my ($self) = @_;
  my @vertex_lines = map qq["$_";], $self->V->@*;
  my @edge_lines = map { sprintf qq["%s" -- "%s";], $_->@[0,1] } $self->E;
  my $dot = join "\n", @vertex_lines, @edge_lines;
  return "graph G {\n$dot\n}\n";
}

sub to_dot {
  my ($self) = @_;
  my @V = $self->V->@*;
  my @vertex_lines = map qq["$_";], @V;

  my @edge_lines;
  for my $i (0 .. $#V-1) {
    for my $j ($i+1 .. $#V) {
      push @edge_lines, sprintf qq["%s" -- "%s";], $V[$i], $V[$j]
        if $self->are_adjacent($V[$i], $V[$j]);
    }
  }
  my $dot = join "\n", @vertex_lines, @edge_lines;
  return "graph G {\n$dot\n}\n";
}

sub components {
  my ($self) = @_;
  my @components;
  my @V = $self->V->@*;
  my %used;
  while (@V) {
    my $V = shift @V;
    next if $used{$V};
    my @queue = ($V);
    my @component;

    # DFS starting from V
    while (@queue) {
      my $v = shift @queue;
      next if $used{$v}++;
      push @component, $v;
      push @queue, $self->neighbors($v);
    }
    push @components, \@component;
  }
  return @components;
}

sub subgraph {
  my ($self, @subV) = @_;
  my %V = map { $_ => 1 } @subV;
  my $S = $self->new_graph(\@subV);
  for my $e ($self->E) {
    if ($V{$e->[0]} && $V{$e->[1]}) {
      $S->add_edge($e);
    }
  }
  return $S;
}

# This finds a maximal independent set of a possibly not-connected graph
# be decomposing it into components and solving the problem on each subcomponent
sub mis {
  my ($self) = @_;
  my @mis;
  for my $c ($self->components) {
    my $s = $self->subgraph(@$c);
    push @mis, $s->mis_component->@*;
  }
  return wantarray ? @mis : \@mis;
}

# This finds a maximal independent set in a graph, but for disconnected
# graphs it may be a lot faster to use ->mis
use Time::HiRes ();
sub mis_component {
  my ($self) = @_;
  my @V = sort special_vertex_sort $self->V->@*;

  my $start = Time::HiRes::time();

  my $best_mis = [];
  my @queue = ([[], \@V]);
  my $count = 0;

  # DFS starting from the empty set
  while (@queue) {
    my ($set, $pool) = pop(@queue)->@*;
    next if @$set + @$pool <= @$best_mis;

    $best_mis = $set if @$set > @$best_mis;

    my ($first, @new_pool) = @$pool;
    next unless defined $first;
    push @queue, [   $set          , \@new_pool ];

    unless ($self->adjacent_any($first, @$set)) {
      my $smaller_pool = $self->remove_neighbors_of($first, \@new_pool);
      push @queue, [ [ @$set, $first], $smaller_pool ] if
        @$set + 1 + @$smaller_pool > @$best_mis;
    }

    die "Timed out" if ++$count % 100000 == 0 && Time::HiRes::time() - $start > 10;

  }
  return wantarray ? @$best_mis : $best_mis;
}

sub special_vertex_sort {
  my ($amatch, $bmatch) = (scalar($a =~ /^(\d+),\1$/),
                           scalar($b =~ /^(\d+),\1$/));
  if    (  $amatch && ! $bmatch) { return -1 }
  elsif (! $amatch &&   $bmatch) { return 1 }
  else { return 0 }
}

1;
