//
//  ViewController.swift
//  ZoomedTransition
//
//  Created by Ashish Dutt on 11/08/25.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private var selectedIndexPath: IndexPath?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.collectionViewLayout = createCompositionalLayout()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.navigationController?.delegate = self
        self.transitioningDelegate = self
    }
    
    fileprivate func createCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let layout = UICollectionViewCompositionalLayout { (sectionIndex: Int, environment: NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection? in
            let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(50))
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            if sectionIndex == 0 {
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitem: item, count: 2)
                group.interItemSpacing = .fixed(10)
                
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
                section.interGroupSpacing = 10
                return section
            } else if sectionIndex == 1 {
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitems: [item])
                group.interItemSpacing = .fixed(10)
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
                section.interGroupSpacing = 10
                return section
                
            } else if sectionIndex == 2 {
                let group = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitem: item, count: 3)
                group.interItemSpacing = .fixed(10)
                let section = NSCollectionLayoutSection(group: group)
                section.contentInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
                section.orthogonalScrollingBehavior = .continuous
                section.interGroupSpacing = 10
                return section
            } else {
                let innerGroup = NSCollectionLayoutGroup.horizontal(layoutSize: itemSize, subitem: item, count: 2)
                innerGroup.interItemSpacing = .fixed(10)
                let outerGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .estimated(150))
                let outerGroup = NSCollectionLayoutGroup.vertical(layoutSize: outerGroupSize, subitem: innerGroup, count: 2)
                outerGroup.interItemSpacing = .fixed(10)
                
                let section = NSCollectionLayoutSection(group: outerGroup)
                section.contentInsets = .init(top: 10, leading: 16, bottom: 10, trailing: 16)
                section.interGroupSpacing = 10
                section.orthogonalScrollingBehavior = .groupPaging
                return section
            }
        }
        
        return layout
    }
    
    @objc private func dismissPresentedVC() {
        dismiss(animated: true)
    }

}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 4
        } else if section == 1 {
            return 2
        } else if section == 2 {
            return 6
        } else {
            return 8
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dummyCell", for: indexPath)
        let label = cell.viewWithTag(100) as? UILabel
        label?.text = "\(indexPath.row + 1)"
        if indexPath.section == 0 {
            cell.contentView.backgroundColor = .systemBlue
        } else if indexPath.section == 1 {
            cell.contentView.backgroundColor = .systemRed
        } else if indexPath.section == 2 {
            cell.contentView.backgroundColor = .systemGreen
        } else {
            cell.contentView.backgroundColor = .systemPink
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        let section = indexPath.section
        let cell = collectionView.cellForItem(at: indexPath)
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "DummyDetailVC") as! DummyDetailVC
        let label = vc.view.viewWithTag(100) as? UILabel
        let outerView = label?.superview
        label?.text = "Details of Section \(section + 1) Row \(indexPath.row + 1)"
        vc.title = "Details"
        outerView?.backgroundColor = cell?.contentView.backgroundColor
        if section % 2 == 0 {
            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(
                    barButtonSystemItem: .close,
                    target: self,
                    action: #selector(dismissPresentedVC)
                )
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .custom
            nav.transitioningDelegate = self
            present(nav, animated: true)
        } else {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK: - UINavigationControllerDelegate (Push/Pop)
extension ViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController,
                              animationControllerFor operation: UINavigationController.Operation,
                              from fromVC: UIViewController,
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let selectedIndexPath, let cell = collectionView.cellForItem(at: selectedIndexPath) else { return nil }
        // We only want to animate between our list and detail
        if operation == .push, fromVC === self, toVC is DummyDetailVC {
            return SharedZoomTransitionAnimator(type: .push, originView: cell)
        }
        if operation == .pop, fromVC is DummyDetailVC, toVC === self {
            return SharedZoomTransitionAnimator(type: .pop, originView: cell)
        }
        return nil
    }
}

// MARK: - UIViewControllerTransitioningDelegate (Present/Dismiss)
extension ViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController,
                             presenting: UIViewController,
                             source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let selectedIndexPath, let cell = collectionView.cellForItem(at: selectedIndexPath) else {
            return nil
        }
        return SharedZoomTransitionAnimator(type: .present, originView: cell)
    }

    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        guard let selectedIndexPath,
                  let cell = collectionView.cellForItem(at: selectedIndexPath) else {
                return nil
            }
            return SharedZoomTransitionAnimator(type: .dismiss, originView: cell)
    }
}

//            if #available(iOS 18.0, *) {
//                nav.preferredTransition = .zoom(sourceViewProvider: { context in
//                    return cell
//                })
//            } else {
//                nav.modalTransitionStyle = .crossDissolve
//            }

//            if #available(iOS 18.0, *) {Instance will be immediately deallocated because property 'transitioningDelegate' is 'weak'
//                vc.preferredTransition = .zoom(sourceViewProvider: { context in
//                    return cell
//                })
//            }
