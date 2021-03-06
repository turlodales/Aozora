//
//  AnimeListViewController.swift
//  AnimeNow
//
//  Created by Paul Chavarria Podoliako on 6/21/15.
//  Copyright (c) 2015 AnyTap. All rights reserved.
//

import UIKit
import ANCommonKit

import XLPagerTabStrip

protocol AnimeListControllerDelegate: class {
    func controllerRequestRefresh() -> BFTask
}

class AnimeListViewController: UIViewController {
    
    weak var delegate: AnimeListControllerDelegate?
    
    var animator: ZFModalTransitionAnimator!
    var animeListType: AnimeList!
    var currentLayout: LibraryLayout = .CheckIn
    var currentSortType: SortType = .Title
    
    var currentConfiguration: Configuration! {
        didSet {
            
            for (filterSection, value, _) in currentConfiguration {
                if let value = value {
                    switch filterSection {
                    case .Sort:
                        let sortType = SortType(rawValue: value)!
                        if isViewLoaded() {
                            updateSortType(sortType)
                        } else {
                            currentSortType = sortType
                        }
                    case .View:
                        let layoutType = LibraryLayout(rawValue: value)!
                        if isViewLoaded() {
                            updateLayout(layoutType, withSize: view.bounds.size)
                        } else {
                            currentLayout = layoutType
                        }
                        
                    default: break
                    }
                }
            }
        }
    }
    var refreshControl = UIRefreshControl()
    
    var animeList: [Anime] = [] {
        didSet {
            if collectionView != nil {
                collectionView.reloadData()
            }
        }
    }
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    func initWithList(animeList: AnimeList, configuration: Configuration) {
        self.animeListType = animeList
        self.currentConfiguration = configuration
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateLayout(currentLayout, withSize: view.bounds.size)
        updateSortType(currentSortType)
        addRefreshControl(refreshControl, action: "refreshLibrary", forCollectionView: collectionView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        refreshControl.endRefreshing()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)

        if UIDevice.isPad() {
            updateLayout(currentLayout, withSize: size)
        }
    }
    
    func refreshLibrary() {
        
        delegate?.controllerRequestRefresh().continueWithExecutor(BFExecutor.mainThreadExecutor(), withBlock: { (task: BFTask!) -> AnyObject! in
            
            self.refreshControl.endRefreshing()
            
            if let error = task.error {
                print("\(error)")
            }
            return nil
        })
        
    }
    
    // MARK: - Sort and Layout
    
    func updateLayout(layout: LibraryLayout, withSize viewSize: CGSize) {
        
        currentLayout = layout
        
        guard let collectionView = collectionView,
            let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
                return
        }
        
        switch currentLayout {
        case .CheckIn:
            let insets: CGFloat = UIDevice.isPad() ? 15 : 8

            let columns: CGFloat = UIDevice.isLandscape() ? 3 : 2
            let cellHeight: CGFloat = 165
            var cellWidth: CGFloat = 0
            
            layout.sectionInset = UIEdgeInsets(top: insets, left: insets, bottom: insets, right: insets)
            layout.minimumLineSpacing = CGFloat(insets)
            layout.minimumInteritemSpacing = CGFloat(insets)
            
            if UIDevice.isPad() {
                cellWidth = (viewSize.width - (columns+1) * insets) / columns
            } else {
                cellWidth = viewSize.width - (insets*2)
            }
            
            layout.itemSize = CGSize(width: cellWidth, height: cellHeight)
        case .Compact:
            let margin: CGFloat = 4
            let columns: CGFloat = UIDevice.isPad() ? (UIDevice.isLandscape() ? 14 : 10) : 5
            let totalWidth: CGFloat = viewSize.width - (margin * (columns + 1))
            let width = totalWidth / columns
            
            layout.sectionInset = UIEdgeInsets(top: margin, left: margin, bottom: margin, right: margin)
            layout.minimumLineSpacing = margin
            layout.minimumInteritemSpacing = margin
            layout.itemSize = CGSize(width: width, height: width/83*116)
        }

        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.reloadData()
    }
    
    func updateSortType(sortType: SortType) {
        
        currentSortType = sortType
    
        switch self.currentSortType {
        case .Rating:
            animeList.sortInPlace({ $0.rank < $1.rank && $0.rank != 0 })
        case .Popularity:
            animeList.sortInPlace({ $0.popularityRank < $1.popularityRank })
        case .Title:
            animeList.sortInPlace({ $0.title < $1.title })
        case .NextAiringEpisode:
            animeList.sortInPlace({ (anime1: Anime, anime2: Anime) in
                
                let startDate1 = anime1.nextEpisodeDate ?? NSDate(timeIntervalSinceNow: 60*60*24*1000)
                let startDate2 = anime2.nextEpisodeDate ?? NSDate(timeIntervalSinceNow: 60*60*24*1000)
                return startDate1.compare(startDate2) == .OrderedAscending
            })
        case .Newest:
            animeList.sortInPlace({ (anime1: Anime, anime2: Anime) in
                
                let startDate1 = anime1.startDate ?? NSDate()
                let startDate2 = anime2.startDate ?? NSDate()
                return startDate1.compare(startDate2) == .OrderedDescending
            })
        case .Oldest:
            animeList.sortInPlace({ (anime1: Anime, anime2: Anime) in
                
                let startDate1 = anime1.startDate ?? NSDate()
                let startDate2 = anime2.startDate ?? NSDate()
                return startDate1.compare(startDate2) == .OrderedAscending
                
            })
        case .MyRating:
            animeList.sortInPlace({ (anime1: Anime, anime2: Anime) in
                
                let score1 = anime1.progress!.score ?? 0
                let score2 = anime2.progress!.score ?? 0
                return score1 > score2
            })
        case .NextEpisodeToWatch:
            animeList.sortInPlace({ (anime1: Anime, anime2: Anime) in
                let nextDate1 = anime1.progress!.nextEpisodeToWatchDate ?? NSDate(timeIntervalSinceNow: 60*60*24*365*100)
                let nextDate2 = anime2.progress!.nextEpisodeToWatchDate ?? NSDate(timeIntervalSinceNow: 60*60*24*365*100)
                return nextDate1.compare(nextDate2) == .OrderedAscending
            })
            break;
        default:
            break;
        }
        
        if isViewLoaded() {
            collectionView.reloadData()
        }
    }
    
}


extension AnimeListViewController: UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return animeList.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        switch currentLayout {
        case .CheckIn:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("CheckIn", forIndexPath: indexPath) as! AnimeLibraryCell
            
            let anime = animeList[indexPath.row]
            cell.delegate = self
            cell.configureWithAnime(anime, showLibraryEta: true)
            cell.layoutIfNeeded()
            return cell
        
        case .Compact:
            let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Compact", forIndexPath: indexPath) as! BasicCollectionCell
            
            let anime = animeList[indexPath.row]
            cell.titleimageView.setImageFrom(urlString: anime.imageUrl, animated: false)
            cell.layoutIfNeeded()
            return cell
        }
    }
}



extension AnimeListViewController: UICollectionViewDelegate {
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let anime = animeList[indexPath.row]
        self.animator = presentAnimeModal(anime)
    }
}

extension AnimeListViewController: AnimeLibraryCellDelegate {
    func cellPressedWatched(cell: AnimeLibraryCell, anime: Anime) {
        if let progress = anime.progress {

            if progress.myAnimeListList() == .Completed {
                RateViewController.showRateDialogWith(self.tabBarController!, title: "You've finished\n\(anime.title!)!\ngive it a rating", initialRating: Float(progress.score)/2.0, anime: anime, delegate: self)
            }

            cell.configureWithAnime(anime, showLibraryEta: true)
        }
    }
    
    func cellPressedEpisodeThread(cell: AnimeLibraryCell, anime: Anime, episode: Episode) {
        
        let threadController = Storyboard.customThreadViewController()
        threadController.initWithEpisode(episode, anime: anime)
        
        if !InAppController.hasAnyPro() {
            threadController.interstitialPresentationPolicy = .Automatic
        }
        
        navigationController?.pushViewController(threadController, animated: true)
    }
}

extension AnimeListViewController: RateViewControllerProtocol {
    func rateControllerDidFinishedWith(anime anime: Anime, rating: Float) {
        RateViewController.updateAnime(anime, withRating: rating*2.0)
    }
}

extension AnimeListViewController: XLPagerTabStripChildItem {
    func titleForPagerTabStripViewController(pagerTabStripViewController: XLPagerTabStripViewController!) -> String! {
        return animeListType.rawValue
    }
    
    func colorForPagerTabStripViewController(pagerTabStripViewController: XLPagerTabStripViewController!) -> UIColor! {
        return UIColor.whiteColor()
    }
}
