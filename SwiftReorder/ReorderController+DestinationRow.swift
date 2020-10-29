//
// Copyright (c) 2016 Adam Shin
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

import UIKit

extension CGRect {
    
    init(center: CGPoint, size: CGSize) {
        self.init(x: center.x - (size.width / 2), y: center.y - (size.height / 2), width: size.width, height: size.height)
    }
    
}

extension ReorderController {
    
    func updateDestinationRow() {
        guard case .reordering(let context) = reorderState,
            let tableView = tableView,
            let proposedNewDestinationRow = proposedNewDestinationRow(),
            let newDestinationRow = delegate?.tableView(tableView, targetIndexPathForReorderFromRowAt: context.destinationRow, to: proposedNewDestinationRow, snapshot: snapshotView),
            newDestinationRow != context.destinationRow
        else { return }
        
        var newContext = context
        newContext.destinationRow = newDestinationRow
        reorderState = .reordering(context: newContext)
        
        delegate?.tableView(tableView, reorderRowAt: context.destinationRow, to: newContext.destinationRow)
        
        tableView.beginUpdates()
        tableView.deleteRows(at: [context.destinationRow], with: .fade)
        tableView.insertRows(at: [newContext.destinationRow], with: .fade)
        tableView.endUpdates()
    }
    
    func proposedNewDestinationRow() -> IndexPath? {
        guard case .reordering(let context) = reorderState,
            let tableView = tableView,
            let superview = tableView.superview,
            let snapshotView = snapshotView
        else { return nil }
        
        let snapshotFrameInSuperview = CGRect(center: snapshotView.center, size: snapshotView.bounds.size)
        let snapshotFrame = superview.convert(snapshotFrameInSuperview, to: tableView)
        
        let availablePaths = tableView.visibleCells.compactMap { (cell) -> (path:IndexPath, overlapPercent: CGFloat)? in
            // Workaround for an iOS 11 bug.
            
            // When adding a row using UITableView.insertRows(...), if the new
            // row's frame will be partially or fully outside the table view's
            // bounds, and the new row is not the first row in the table view,
            // it's inserted without animation.
            
            let cellOverlapsTopBounds = cell.frame.minY < tableView.bounds.minY + 5
            let indexPath = tableView.indexPath(for: cell) ?? IndexPath(row: 0, section: 0)
            
            let overlapPercent = rectIntersectionInPerc(r1: snapshotFrame, r2: cell.frame)
            
            guard overlapPercent > 0 else {
                return nil
            }
            
            let cellIsFirstCell = indexPath == IndexPath(row: 0, section: 0)
            
            guard (!cellOverlapsTopBounds || cellIsFirstCell) else {
                return nil
            }
            
            return (indexPath, overlapPercent)
        }
        
        guard !availablePaths.contains(where: { (path, overlapPercent) -> Bool in
            return path == context.destinationRow
        }), let selectedPath = availablePaths.max(by: { $0.overlapPercent < $1.overlapPercent }) else {
            return nil
        }
        
        //check
        if context.overRow != selectedPath.path {
            var newContext = context
            newContext.overRow = selectedPath.path
            reorderState = .reordering(context: newContext)
            delegate?.tableView(tableView, sourceIndexPath: newContext.sourceRow, overIndexPath: newContext.overRow, snapshot: snapshotView)
        }
        
        if selectedPath.overlapPercent > overlapThreshold {
            return nil
        }
        
        return selectedPath.path
    }
    
    func rectForEmptySection(_ section: Int) -> CGRect {
        guard let tableView = tableView else { return .zero }
        
        let sectionRect = tableView.rectForHeader(inSection: section)
		return sectionRect.inset(by: UIEdgeInsets(top: sectionRect.height, left: 0, bottom: 0, right: 0))
    }
    
    //Width and Height of both rects may be different
    func rectIntersectionInPerc(r1:CGRect, r2:CGRect) -> CGFloat {
        if (r1.intersects(r2)) {
            let interRect:CGRect = r1.intersection(r2);
            
            let interRectArea = interRect.width * interRect.height
            let r1Area = r1.width * r1.height
            let r2Area = r2.width * r2.height
            
            return (interRectArea / ((r1Area + r2Area)/2.0) * 100.0)
        }
        return 0;
    }
}
