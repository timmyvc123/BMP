//
//  MainScreenViewController.swift
//  BetaBump
//
//  Created by Timmy Van Cauwenberge on 2/17/21.
//

import UIKit
import AVFoundation
import Kingfisher
import Spartan

class MainScreenViewController: UIViewController {
    
    @IBOutlet weak var songNameLabel: UILabel!
    @IBOutlet weak var albumCoverImageView: UIImageView!
    @IBOutlet weak var musicButton: UIButton!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet weak var pauseButton: UIButton!
    
    private let client = APIClient(configuration: .default)
    let player = AudioPlayer.shared.player
    var previewURL: URL? = nil
    var search: SearchTracks!
    var searchType: SpotifyType!
    
    let token = (UserDefaults.standard.string(forKey: "token"))
    
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playButton.isHidden = true
        Spartan.authorizationToken = token
//        fetchUserInfo()
//        createPlaylist()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if (!appDelegate.hasAlreadyLaunched) {
            appDelegate.sethasAlreadyLaunched()
            displayPlaylistCreationMessage()
        }
        
    }
    
    @IBAction func musicButtonTapped(_ sender: Any) {
//        fetchAndConfigureSearch()
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        
    }
    
    @IBAction func pauseButtonTapped(_ sender: Any) {
        
        if ((player?.isPlaying) != nil) {
            print("playing")
        }
        player?.pause()
    }
    
    func fetchAndConfigureSearch() {
        
        let randomOffset = Int.random(in: 0..<1000)
        print("random NUmber is ", randomOffset)

        client.call(request: .search(token: token!, q: getRandomSearch(), type: .track, market: "US", limit: 1, offset: randomOffset) { [self] result in
            
                let tracks = result as? Result<SearchTracks, Error>
                
                switch tracks {
                
                case .success(let something):

                    for track in something.tracks.items {
                        let newTrack = SimpleTrack(artistName: track.album.artists.first?.name,
                                                   id: track.id,
                                                   title: track.name,
                                                   previewURL: track.previewUrl,
                                                   images: track.album.images!,
                                                   albumName: track.album.name)
                        
                        self.songNameLabel.text = newTrack.title + " By: " + newTrack.artistName!
                        
                        let coverImageURL = newTrack.images[0].url
                        self.albumCoverImageView.kf.setImage(with: coverImageURL)
                        
                        previewURL = newTrack.previewUrl
                        
                        if previewURL == nil {
                            player?.pause()
                        } else {
                            AudioPlayer.shared.downloadFileFromURL(url: previewURL!)
                        }
                        
                        print("The new track is...", newTrack)
                    }

                case .failure(let error):
                    print("search query failed bc... ", error)
                case .none:
                    print("not decoding correctly")
                }
            })
    }
    
    private func fetchUserInfo() {
        
        var user: UserModel!
        
        client.call(request: .getUserInfo(token: token!, completion: { (result) in
            
            switch result {
            case .failure(let error):
                print("this is the error1", error)
            case .success(let currUser):
                DispatchQueue.main.async {
//                    self.createPlaylist(user: currUser)
//                    self.userID = currUser.id
                    user = currUser
                    
                    
                    
                    print("Current user: ", currUser)
                  print("This is the username:", user.displayName)
                }
            }
            
        }))
    }


    func createPlaylist() {
        
        let name = "BMP"
        
        //get current user
        let getUser = Spartan.getMe { (user) in
            
            //create playlist
            let createPlaylist = Spartan.createPlaylist(userId: user.id as! String, name: name, isPublic: true) { (playlist) in
                
                print("PLAYLIST CREATED")
                
            } failure: { (error) in
                print("Error creating playlist: ", error)
            }
            
        } failure: { (error) in
            print("Getting User Info Error: ", error)
        }
    }
    
    
    //MARK: Helpers
    
    func displayPlaylistCreationMessage() {
        let message = "BMP would like to create a playlist on your Spotify account so your liked songs can be autmatically added to it."
        
        let alert = UIAlertController(title: "BMP Playlist", message: message, preferredStyle: .alert)
        
        let declineAction = UIAlertAction(title: "Decline", style: .destructive) { (action) in
            print("Declined")
        }
        
        let acceptAction = UIAlertAction(title: "Create", style: .default) { (action) in
            self.createPlaylist()
            print("Accepted")
        }
        
        alert.addAction(declineAction)
        alert.addAction(acceptAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    func getRandomLetter(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyz"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
    
    func getRandomSearch() -> String {
        let randomChar = getRandomLetter(length: 1)
        var randomSearch = ""
        
        // Places the wildcard character at the beginning, or both beginning and end, randomly.
        randomSearch = randomChar + "%"

        print("random search = ", randomSearch)
        
        return randomSearch
    }
    
}
