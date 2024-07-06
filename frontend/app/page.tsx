'use client'
import React, { useEffect, useState } from 'react'
import { getAllNFTs, NFT } from './Queries/TokenQueries';
import Link from 'next/link';

const MainPage = () => {
    const [loading, setLoading] = useState<boolean>(true);
    const [NFTs, setNFTS] = useState<NFT[]>([]);
    useEffect(() => {
      getAllNFTs().then((nfts)=>{
            setNFTS(nfts);
            setLoading(false);
        })
    }, []);

  return (
    <div className='flex flex-wrap gap-8'>
        {NFTs.map(nft=>(
            <Link key={nft.id} href={`/token/${nft.id}`}>
                <div className='w-[150px] h-[250px] flex flex-col g-1'>
                    <img src={nft.image} width={150} height={150}></img>  
                    <a className='w-[150px] text-wrap text-xs mt-2'>name: {nft.name}</a>
                </div>
            </Link>
            
        ))}
    </div>
  )
}

export default MainPage