//
//  MinHeap.swift
//  Hi5
//
//  Created by 李凯翔 on 2022/7/11.
//

import Foundation

struct heap<T>{
    var nodes = [T]()
    
    private var orderCriteria:(T,T) -> Bool
    
    public init(sort:@escaping (T,T) -> Bool){
        self.orderCriteria = sort
    }
    
    public init(array:[T],sort:@escaping(T,T) -> Bool){
        self.orderCriteria = sort
        configureHeap(from: array)
    }
    
    private mutating func configureHeap(from array: [T]){
        nodes = array
        for i in stride(from: nodes.count/2-1, through: 0, by: -1){
            shiftDown(i)
        }
    }
    
    var isEmpty:Bool{
        return nodes.isEmpty
    }
    
    var count:Int {
        return nodes.count
    }
    
    func parentIndex(ofIndex i:Int) -> Int{
        return (i-1)/2
    }
    
    func leftChildIndex(ofIndex i:Int) -> Int{
        return 2*i + 1
    }
    
    func rightChildIndex(ofIndex i :Int) -> Int{
        return 2*i + 2
    }
    
    public func peek() -> T?{
        return nodes.first
    }
    
    public mutating func insert(_ value:T){
        nodes.append(value)
        shiftUp(nodes.count - 1)
    }
    
    public mutating func insert<S:Sequence>(_ sequence:S) where S.Iterator.Element == T{
        for value in sequence{
            insert(value)
        }
    }
    
    @discardableResult public mutating func remove() -> T?{
        guard !nodes.isEmpty else {return nil}
        
        if nodes.count == 1{
            return nodes.removeLast()
        }else{
            let value = nodes[0]
            nodes[0] = nodes.removeLast()
            shiftDown(0)
            return value
        }
    }
    
    mutating func shiftUp(_ index: Int){
        var childIndex = index
        let child = nodes[childIndex]
        var parentIndex = self.parentIndex(ofIndex: childIndex)
        
        while childIndex > 0 && orderCriteria(child,nodes[parentIndex]){
            nodes[childIndex] = nodes[parentIndex]
            childIndex = parentIndex
            parentIndex = self.parentIndex(ofIndex: childIndex)
        }
        
        nodes[childIndex] = child
    }
    
    mutating func shiftDown(from index:Int,until endIndex:Int){
        let leftChildIndex = self.leftChildIndex(ofIndex: index)
        let rightChildIndex = leftChildIndex + 1
        
        var first = index
        if leftChildIndex < endIndex && orderCriteria(nodes[leftChildIndex],nodes[first]){
            first = leftChildIndex
        }
        
        if rightChildIndex < endIndex && orderCriteria(nodes[rightChildIndex],nodes[first]){
            first = rightChildIndex
        }
        
        if first == index {return}
        
        nodes.swapAt(index, first)
        shiftDown(from: first, until: endIndex)
    }
    
    mutating func shiftDown(_ index:Int){
        shiftDown(from: index, until: nodes.count)
    }
    
    @discardableResult public mutating func remove(at index: Int) -> T? {
        guard index < nodes.count else { return nil }
        
        let size = nodes.count - 1
        if index != size {
          nodes.swapAt(index, size)
          shiftDown(from: index, until: size)
          shiftUp(index)
        }
        return nodes.removeLast()
      }
      
    public mutating func replace(index i: Int, value: T) {
        guard i < nodes.count else { return }
        
        remove(at: i)
        insert(value)
      }
}

extension heap where T: Equatable {
  
  /** Get the index of a node in the heap. Performance: O(n). */
    internal func index(of node: T) -> Int? {
        return nodes.firstIndex(where: { $0 == node })
  }
  
  /** Removes the first occurrence of a node from the heap. Performance: O(n). */
    @discardableResult internal mutating func remove(node: T) -> T? {
    if let index = index(of: node) {
      return remove(at: index)
    }
    return nil
  }

}
