#ifndef TREE_HPP
#define TREE_HPP

#include <iostream>
#include "myassert.h"
#include "genio.h"
//#include <vector>
#include "dynarray.h"
#include <algorithm>
#ifdef USE_LAMBDA
#include <boost/lambda/lambda.hpp>
namespace lambda=boost::lambda;
#endif
#include <functional>
#include "config.h"
#include "graphviz.hpp"
//#include "symbol.hpp"
#include "byref.hpp"

#ifdef TEST
#include "test.hpp"
#endif

using namespace std;

//template <class L, class A> struct Tree;

// Tree owns its own child pointers list but not trees it points to! - routines for creating trees through new and recurisvely deleting are provided outside the class.  Reading from a stream does create children using new.
// FIXME: need two allocators (or always rebind/copy from one) instead of just new/deleting Self
template <class L, class Alloc=std::allocator<void *> > struct Tree : private Alloc {
  typedef Tree Self;
  typedef L Label;
  Label label;
  typedef rank_type Rank;
  Rank rank;
private:
  //Tree(const Self &t) : {}
  Self **children;

public:
  template<class T>
  T &leaf_data() {
        Assert(rank==0);
        Assert(sizeof(T) <= sizeof(children));
        return *(reinterpret_cast<T*>(&children));
  }
  template<class T>
  const T &leaf_data() const {
        return const_cast<Self *>(this)->leaf_data<T>();
  }
/*
  int &leaf_data_int() {
        Assert(rank==0);
        return *(reinterpret_cast<int *>(&children));
  }
  void * leaf_data() const {
        return const_cast<Self *>(this)->leaf_data();
  }
  int leaf_data_int() const {
        return const_cast<Self *>(this)->leaf_data();
  }
  */

  Rank size() const {
        return rank;
  }
  Tree() : rank(0) {}
  explicit Tree (const Label &l) : rank(0),label(l) {  }
  Tree (const Label &l,Rank n) : label(l) { alloc(n); }
  explicit Tree (const char *c) {
        std::istringstream ic(c);ic >> *this;
  }
  void alloc(Rank _rank) {
        rank=_rank;
#ifdef TREE_SINGLETON_OPT
        if (rank>1)
#else
        if (rank)
#endif
          children = (Self **)this->allocate(rank);
  }
  Tree(Rank _rank,Alloc _alloc=Alloc()) : Alloc(_alloc) {
        alloc(_rank);
  }
  void dump_children() {
        dealloc();
  }
  void create_children(unsigned n) {
        alloc(n);
  }
  void set_rank(unsigned n) {
        dealloc();
        alloc(n);
  }
  void dealloc() {
#ifdef TREE_SINGLETON_OPT
        if (rank>1)
#else
        if (rank)
#endif
          this->deallocate((void **)children,rank);
        rank=0;
  }
  void dealloc_recursive();

  ~Tree() {
        dealloc();
  }
  // STL container stuff
  typedef Self *value_type;
  typedef value_type *iterator;

  typedef const Self *const_value_type;
  typedef const const_value_type *const_iterator;

  value_type & child(Rank i) {
#ifdef TREE_SINGLETON_OPT
        if (rank == 1) {
          Assert(i==0);
          return *(value_type *)children;
        }
#endif
        return children[i];
  }
  value_type & operator [](Rank i) { return child(i); }


  iterator begin() {
#ifdef TREE_SINGLETON_OPT
        if (rank == 1)
          return (iterator)&children;
        else
#endif
          return children;
  }
  iterator end() {
#ifdef TREE_SINGLETON_OPT
        if (rank == 1)
          return ((iterator)&children) + 1;
        else
#endif
          return children+rank;
  }
  const_iterator begin() const {
        return const_cast<Self *>(this)->begin();
  }
  const_iterator end() const {
        return const_cast<Self *>(this)->end();
  }
  template <class T>
friend size_t tree_count(const T *t);
  template <class T>
friend size_t tree_height(const T *t);

  //height = maximum length path from root
  size_t height() const
{
  return tree_height(this);
}

        size_t count_nodes() const
        {
          return tree_count(this);
        }
template <class charT, class Traits>
std::ios_base::iostate print_on(std::basic_ostream<charT,Traits>& o) const
  {
  o << label;
  if (rank) {
        o << '(';
        bool first=true;
        for (const_iterator i=begin(),e=end();i!=e;++i) {
          if (first)
                first = false;
          else
                o << ' ';
          o << **i;
        }
        o << ')';
  }
  return GENIOGOOD;
}

    /*
    template <class charT, class Traits, class Writer>
    std::ios_base::iostate print_graphviz(std::basic_ostream<charT,Traits>& o,Writer writer, const char *treename="T") const {
        o << "digraph ";
        out_quote(o,treename);
        o << " {\n";
        print_graphviz_rec(o,writer,0);
        o << "}\n";
        return GENIOGOOD;
    }
    template <class charT, class Traits, class Writer>
    void print_graphviz_rec(std::basic_ostream<charT,Traits>& o,Writer writer,unsigned node_no) const {
        for (const_iterator i=begin(),e=end();i!=e;++i) {
            i->print_graphviz_rec(o,writer,++node_no);
        }
    }
    */
//template <class T, class charT, class Traits>  friend
  template <class charT, class Traits, class Reader>
  static Self *read_tree(std::basic_istream<charT,Traits>& in,Reader r) {
  Self *ret = new Self;
  std::ios_base::iostate err = std::ios_base::goodbit;
  if (ret->get_from(in,r))
        in.setstate(err);
  if (!in.good()) {
        delete_tree(ret);
        return NULL;
  }
  return ret;

  }

template <class charT, class Traits>
  static Self *read_tree(std::basic_istream<charT,Traits>& in) {
        return read_tree(in,DefaultReader<Label>());
  }

template <class T>
friend void delete_tree(T *);

#ifdef DEBUG_TREEIO
#define DBTREEIO(a) DBP(a)
#else
#define DBTREEIO(a)
#endif

// Reader passed by value, so can't be stateful (unless itself is a pointer to shared state)
template <class charT, class Traits, class Reader>
std::ios_base::iostate get_from(std::basic_istream<charT,Traits>& in,Reader read)
// doesn't free old children if any
{
  char c;
  rank=0;
  DynamicArray<Self *> in_children;
  EXPECTI_COMMENT_FIRST(in>>c);
  if (c == '(') {
      EXPECTI_COMMENT(deref(read)(in,label));
  } else {
      in.unget();
      EXPECTI_COMMENT_FIRST(deref(read)(in,label));
      EXPECTI_COMMENT_FIRST(in >> c);
      if (in.eof()) // since c!='(' before in>>c, can almost not test for this - but don't want to unget() if nothing was read.
          return GENIOGOOD;
      if (c!='(') {
          in.unget();
          return GENIOGOOD;
      }
  } //POST: read a '(' and a label (in either order)
  DBTREEIO(label);
  DBTREEIO('(');
  for(;;) {
      EXPECTI_COMMENT(in>>c);
      if (c == ',')
          EXPECTI_COMMENT(in>>c);
      if (c==')') {
          DBTREEIO(')');
          break;
      }
      in.unget();
      Self *in_child = read_tree(in,read);
      if (in_child) {
          DBTREEIO('!');
          in_children.push_back(in_child);
      } else
          goto fail;
  }
  dealloc();
  alloc((rank_type)in_children.size());
  //copy(in_children.begin(),in_children.end(),begin());
  in_children.moveto(begin());
  return GENIOGOOD;

fail:
  for (typename DynamicArray<Self *>::iterator i=in_children.begin(),end=in_children.end();i!=end;++i)
                  delete_tree(*i);
  return GENIOBAD;

}
};



template <class charT, class Traits,class L,class A>
std::basic_istream<charT,Traits>&
operator >>
 (std::basic_istream<charT,Traits>& is, Tree<L,A> &arg)
{
        return gen_extractor(is,arg,DefaultReader<L>());
        DBTREEIO(std::endl);
}

template <class charT, class Traits,class L,class A>
std::basic_ostream<charT,Traits>&
operator <<
 (std::basic_ostream<charT,Traits>& os, const Tree<L,A> &arg)
{
        return gen_inserter(os,arg);
}






template <class C>
void delete_arg(C &c) {
  delete c;
#ifdef DEBUG
  c=NULL;
#endif
}

template <class T,class F>
bool tree_visit(T *tree,F func)
{
  if (!deref(func).discover(tree))
     return false;
  for (typename T::iterator i=tree->begin(), end=tree->end(); i!=end; ++i)
        if (!tree_visit(*i,func))
                break;
  return deref(func).finish(tree);
}

template <class T,class F>
bool tree_leaf_visit(T *tree,F func)
{
         if (tree->size()) {
             for (T *child=tree->begin(), *end=tree->end();child!=end;++child) {
                 tree_leaf_visit(child,func);
             }
         } else {
           deref(func)(tree);
         }
}


template <class Label,class Labeler=DefaultNodeLabeler<Label> >
struct TreeVizPrinter : public GraphvizPrinter {
    Labeler labeler;
    typedef Tree<Label> T;
    unsigned samerank;
    enum {ANY_ORDER=0,CHILD_ORDER=1,CHILD_SAMERANK=2};


    TreeVizPrinter(ostream &o_,unsigned samerank_=CHILD_SAMERANK,const std::string &prelude="",const Labeler &labeler_=Labeler(),const char *graphname="tree") : GraphvizPrinter(o_,prelude,graphname), labeler(labeler_),samerank(samerank_) {}
    void print(const T &t) {
        print(t,next_node++);
        o << std::endl;
    }
    void print(const T &t,unsigned parent) {
        o << " " << parent << " [";
        labeler.print(o,t.label);
        o << "]\n";
        if (t.rank) {
            unsigned child_start=next_node;
            next_node+=t.rank;
            unsigned child_end=next_node;
            unsigned child=child_start+1;
            if (samerank!=ANY_ORDER)
                if (t.rank > 1) { // ensure left->right order
                    o << " {";
                    if (samerank==CHILD_SAMERANK)
                        o << "rank=same ";
                    o << child_start;
                    for (;child != child_end;++child)
                        o << " -> " << child;
                    o << " [style=invis,weight=0.01]}\n";
                }
            child=child_start;
            for (typename T::const_iterator i=t.begin(),e=t.end();i!=e;++i,++child) {
                o << " " << parent << " -> " << child;
                if (samerank==ANY_ORDER) {
                    //                    o << "[label=" << i-t.begin() << "]";
                }
                o << "\n";
            }
            child=child_start;
            for (typename T::const_iterator i=t.begin(),e=t.end();i!=e;++i,++child) {
                print(**i,child);
            }
        }
    }
};

struct TreePrinter {
  bool first;
  ostream &o;
  TreePrinter(ostream &o_):o(o_),first(true) {}
template <class T>
  bool discover(T *t) {
   if (!first) o<<' ';
   o<<t->label;
   if (t->size()) { o << '('; first=true; }
   return true;
  }
template <class T>
  bool finish(T *t) {
   if (t->size())
    o << ')';
   first=false;
   return true;
  }
};

template <class T,class F>
void postorder(T *tree,F func)
{
  Assert(tree);
  for (typename T::iterator i=tree->begin(), end=tree->end(); i!=end; ++i)
        postorder(*i,func);
  deref(func)(tree);
}

template <class T,class F>
void postorder(const T *tree,F func)
{
  Assert(tree);
  for (typename T::const_iterator i=tree->begin(), end=tree->end(); i!=end; ++i)
        postorder(*i,func);
  deref(func)(tree);
}


template <class T>
void delete_tree(T *tree)
{
  Assert(tree);
  postorder(tree,delete_arg<T *>);
}

template <class L,class A>
void Tree<L,A>::dealloc_recursive() {
        for(iterator i=begin(),e=end();i!=e;++i)
          delete_tree(*i);
        //foreach(begin(),end(),delete_tree<Self>);
        dealloc();
  }

template <class T1,class T2>
bool tree_equal(const T1& a,const T2& b)
{
  if (a.size() != b.size() ||
        !(a.label == b.label))
        return false;
  typename T2::const_iterator b_i=b.begin();
  for (typename T1::const_iterator a_i=a.begin(), a_end=a.end(); a_i!=a_end; ++a_i,++b_i)
        if (!(tree_equal(**a_i,**b_i)))
          return false;
  return true;
}

template <class T1,class T2,class P>
bool tree_equal(const T1& a,const T2& b,P equal)
{
  if ( (a.size()!=b.size()) || !equal(a,b) )
        return false;
  typename T2::const_iterator b_i=b.begin();
  for (typename T1::const_iterator a_i=a.begin(), a_end=a.end(); a_i!=a_end; ++a_i,++b_i)
        if (!(tree_equal(**a_i,**b_i,equal)))
          return false;
  return true;
}

template <class T1,class T2>
struct label_equal_to {
  bool operator()(const T1&a,const T2&b) const {
        return a.label == b.label;
  }
};

template <class T1,class T2>
bool tree_contains(const T1& a,const T2& b)
{
  return tree_contains(a,b,label_equal_to<T1,T2>());
}

template <class T1,class T2,class P>
bool tree_contains(const T1& a,const T2& b,P equal)
{

  if ( !equal(a,b) )
        return false;
  // leaves of b can match interior nodes of a
  if (!b.size())
        return true;
  if( a.size()!=b.size())
        return false;
  typename T1::const_iterator a_i=a.begin();
  for (typename T2::const_iterator b_end=b.end(), b_i=b.begin(); b_i!=b_end; ++a_i,++b_i)
        if (!(tree_contains(**a_i,**b_i,equal)))
          return false;
  return true;
}


template <class L,class A>
inline bool operator !=(const Tree<L,A> &a,const Tree<L,A> &b)
{
  return !(a==b);
}

template <class L,class A>
inline bool operator ==(const Tree<L,A> &a,const Tree<L,A> &b)
{
  return tree_equal(a,b);
}



template <class T>
struct TreeCount {
  size_t count;
  void operator()(const T * tree) {
        ++count;
  }
  TreeCount() : count(0) {}
};

#include <boost/ref.hpp>
template <class T>
size_t tree_count(const T *t)
{
  TreeCount<T> n;
  postorder(t,boost::ref(n));
  return n.count;
}

//height = maximum length path from root
template <class T>
size_t tree_height(const T *tree)
{
    Assert(tree);
  if (!tree->size())
        return 0;
  size_t max_h=0;
  for (typename T::const_iterator i=tree->begin(), end=tree->end(); i!=end; ++i) {
        size_t h=tree_height(*i);
        if (h>=max_h)
          max_h=h;
  }
  return max_h+1;
}

template <class T,class O>
struct Emitter {
  O out;
  Emitter(O o) : out(o) {}
  void operator()(T * tree) {
        out << tree;
  }
};



template <class T,class O>
void emit_postorder(const T *t,O out)
{
#ifndef USE_LAMBDA
  Emitter<T,O &> e(out);
  postorder(t,e);
#else
  postorder(t,o << boost::lambda::_1);
#endif
}


template <class L>
Tree<L> *new_tree(const L &l) {
  return new Tree<L> (l,0);
}

template <class L>
Tree<L> *new_tree(const L &l, Tree<L> *c1) {
  Tree<L> *ret = new Tree<L>(l,1);
  (*ret)[0]=c1;
  return ret;
}

template <class L>
Tree<L> *new_tree(const L &l, Tree<L> *c1, Tree<L> *c2) {
  Tree<L> *ret = new Tree<L>(l,2);
  (*ret)[0]=c1;
  (*ret)[1]=c2;
  return ret;
}

template <class L>
Tree<L> *new_tree(const L &l, Tree<L> *c1, Tree<L> *c2, Tree<L> *c3) {
  Tree<L> *ret = new Tree<L>(l,3);
  (*ret)[0]=c1;
  (*ret)[1]=c2;
  (*ret)[2]=c3;
  return ret;
}

template <class L,class charT, class Traits>
Tree<L> *read_tree(std::basic_istream<charT,Traits>& in)
{
  //return Tree<L>::read_tree(in,DefaultReader<L>());
  return Tree<L>::read_tree(in);
}

#ifdef TEST

template<class T> bool always_equal(const T& a,const T& b) { return true; }

BOOST_AUTO_UNIT_TEST( tree )
{
  Tree<int> a,b,*c,*d,*g=new_tree(1),*h;
  //string sa="%asdf\n1(%asdf\n 2 %asdf\n,%asdf\n3 (4\n ()\n,\t 5,6))";
  string sa="%asdf\n1%asdf\n(%asdf\n 2 %asdf\n,%asdf\n3 (4\n ()\n,\t 5,6))";
  //string sa="1(2 3(4 5 6))";
  string sb="1(2 3(4 5 6))";
  stringstream o;
  istringstream isa(sa);
  isa >> a;
  o << a;
  BOOST_CHECK(o.str() == sb);
  o >> b;
  ostringstream o2;
  TreePrinter tp(o2);
  tree_visit(&a,boost::ref(tp));
  BOOST_CHECK(o.str() == o2.str());
  c=new_tree(1,
                new_tree(2),
                new_tree(3,
                  new_tree(4),new_tree(5),new_tree(6)));
  d=new_tree(1,new_tree(2),new_tree(3));
  istringstream isb(sb);
  h=read_tree<int>(isb);
  //h=Tree<int>::read_tree(istringstream(sb),DefaultReader<int>());
  BOOST_CHECK(a == a);
  BOOST_CHECK(a == b);
  BOOST_CHECK(a == *c);
  BOOST_CHECK(a == *h);
  BOOST_CHECK(a.count_nodes()==6);
  BOOST_CHECK(tree_equal(a,*c,always_equal<Tree<int> >));
  BOOST_CHECK(tree_contains(a,*c,always_equal<Tree<int> >));
  BOOST_CHECK(tree_contains(a,*d,always_equal<Tree<int> >));
  BOOST_CHECK(tree_contains(a,*d));
  BOOST_CHECK(tree_contains(a,b));
  BOOST_CHECK(!tree_contains(*d,a));
  Tree<int> e("1(1(1) 1(1,1,1))"),
                f("1(1(1()),1)");
  BOOST_CHECK(!tree_contains(a,e,always_equal<Tree<int> >));
  BOOST_CHECK(tree_contains(e,a,always_equal<Tree<int> >));
  BOOST_CHECK(!tree_contains(f,e));
  BOOST_CHECK(tree_contains(e,f));
  BOOST_CHECK(tree_contains(a,*g));
  BOOST_CHECK(e.height()==2);
  BOOST_CHECK(f.height()==2);
  BOOST_CHECK(a.height()==2);
  BOOST_CHECK(g->height()==0);
  a.dealloc_recursive();
  b.dealloc_recursive();
  e.dealloc_recursive();
  f.dealloc_recursive();
  delete_tree(c);
  delete_tree(d);
  delete_tree(g);
  delete_tree(h);
  Tree<int> k("1");
  Tree<int> l("1()");
  BOOST_CHECK(tree_equal(k,l));
  BOOST_CHECK(k.rank==0);
  BOOST_CHECK(l.rank==0);
  BOOST_CHECK(l.label==1);
  k.dealloc_recursive();
  l.dealloc_recursive();

}


#endif

#endif
